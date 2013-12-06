IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[media].[prc_FinanceFinalSettled]') AND type in (N'P', N'PC'))
DROP PROCEDURE [media].[prc_FinanceFinalSettled]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[media].[prc_FinanceFinalSettled]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'






CREATE procedure [media].[prc_FinanceFinalSettled] @OperatorId INT,
     @StepNo INT, --0/10数据检查,1备份,2生成摊销,3结帐,4反结帐, 5摊销平衡核对, 9获取当前未&已结账会计期间
     @WillCloseMonthLastDay  DATE,  -- 当前欲结账月的最后一天
     @Scope  INT = 0,  --仅适用于摊销范围：0所有,1按合同,2按支付主体,3按签约帐套
     @ScopeContractID    bigint = NULL as
SET NOCOUNT ON

    declare @Result varchar(120)
    DECLARE @EndDate_TM DATE -- 当前欲结帐期间最后一天
    DECLARE @EndDate_LM DATE -- 上个结帐期间最后一天
    DECLARE	@BeginDate_NM DATE -- 下个结帐期间第一天
    DECLARE @DATE_MIN DATE
    DECLARE @DATE_MAX DATE
    DECLARE @MaxEndDate DATE
    DECLARE @CurrentBegin DATETIME

    SELECT @Result = ''未知错误''
    --SELECT @EndDate_TM = @WillCloseMonthLastDay
    --SELECT @EndDate_LM = DATEADD(day, -1 * DAY(@EndDate_TM), @EndDate_TM)
    EXEC  [media].[prc_FinanceCurrentPeriod] @CurrentBegin = @CurrentBegin OUTPUT
	SELECT @EndDate_LM = DATEADD(DAY, -1, @CurrentBegin)
    SELECT @EndDate_TM = DATEADD(DAY, -1, DATEADD(month, DATEDIFF(MONTH, 0, @EndDate_LM) + 2, 0))
    SELECT @BeginDate_NM = DATEADD(DAY, 1, @EndDate_TM)

    SELECT @DATE_MIN = ''00010101''
    , @DATE_MAX = ''99991231''
    , @MaxEndDate = MAX(PerformEndDate) FROM  media.tbb_Contract;

    IF @StepNo = 2
    BEGIN


		CREATE TABLE #basecontract
		(
			ContractID BIGINT PRIMARY KEY,
			ContractCode VARCHAR(30),
			PlanAmountLM    DECIMAL(10, 2) DEFAULT 0 NOT NULL,
			PlanAmountTM    DECIMAL(10, 2) DEFAULT 0 NOT NULL,
			DaysLM      INT NOT NULL,  -- 执行期截至上月底
			DaysTM      INT NOT NULL,  -- 执行期截至本月底
			ClosedAmountNormal DECIMAL(10, 2)  DEFAULT 0 NOT NULL,
			ClosedAmountPre DECIMAL(10, 2)  DEFAULT 0 NOT NULL,
			RentAmount     DECIMAL(10, 2) NOT NULL,
			BeginDate     DATE,
			EndDate         DATE,
			DaysTTL         INT,
			IsSignFinished        BIT,
			IsAmortized            BIT,
			AmortizeType        VARCHAR(50),
			SignFinishedDate  DATE,
			DealStatus   INT,
			DealSubStatus  INT,
			MaxAmount180  DECIMAL(10, 2)
		)

		CREATE TABLE #amortize
		(
			[ContractID] [bigint] NOT NULL,
			[ContractCode] [varchar](30) NOT NULL,
			[AmortizeYear] [int] NOT NULL,
			[AmortizeMonth] [int] NOT NULL,
			[AmortizeType] [varchar](50) NOT NULL,
			[AmortizeAmount] [decimal](10, 2) NOT NULL,
			[PayAmount] [decimal](10, 2) DEFAULT(0) NOT NULL,
			[PlanPayAmount] [decimal](10, 2) DEFAULT(0) NOT NULL,
			[Formula] [varchar](100) NOT NULL
		)

		CREATE TABLE #Months
		(
			SeqNo INT IDENTITY(1,1),
			StartDate  date,
			EndDate date
		)

		; WITH Month_Base(StartDate, EndDate) AS

		(
			SELECT DATEADD(day, 1 - DAY(@EndDate_TM), @EndDate_TM), @EndDate_TM
			UNION ALL
			SELECT DATEADD(month, 1, StartDate),  DATEADD(DAY, -1, DATEADD(month, 2, StartDate)) FROM  Month_Base WHERE DATEDIFF(mm, EndDate, @MaxEndDate) > 0

		)

		INSERT INTO #Months
				( StartDate ,
				  EndDate
				)
		SELECT StartDate, EndDate FROM  Month_Base ORDER BY StartDate OPTION(MAXRECURSION 0)

		INSERT INTO #basecontract
				( ContractID ,
				  ContractCode ,
				  DaysLM ,
				  DaysTM ,
				  ClosedAmountNormal ,
				  ClosedAmountPre ,
				  RentAmount ,
				  BeginDate ,
				  EndDate ,
				  DaysTTL ,
				  IsSignFinished,
				  IsAmortized,
				  AmortizeType,
				  SignFinishedDate,
				  DealStatus,
				  DealSubStatus,
				  MaxAmount180
				)

		SELECT C.ContractID
		, C.ContractCode
		, media.[GetRangeDays](C.PerformBeginDate, C.PerformEndDate, @DATE_MIN, @EndDate_LM)
		, media.[GetRangeDays](C.PerformBeginDate, C.PerformEndDate, @DATE_MIN, @EndDate_TM)
		, ISNULL(CAH.Normal, 0)
		, ISNULL(CAH.Pre   , 0)
		, C.RentAmount
		, C.PerformBeginDate
		, C.PerformEndDate
		, DATEDIFF(day,C.PerformBeginDate, C.PerformEndDate) + 1
		, C.IsSignFinished
		, CASE WHEN CAH.ContractID IS NOT NULL THEN 1 ELSE 0 END
		, C.AmortizeType
		, C.SignFinishedDate
		, C.DealStatus
		, C.DealSubStatus
		, C.RentAmount * 180 / (DATEDIFF(DAY, C.PerformBeginDate, C.PerformEndDate) + 1)
		FROM media.tbb_Contract C
		 LEFT JOIN (
			SELECT ContractID
			, SUM( CASE WHEN AmortizeType = ''正常'' THEN AmortizeAmount END) as Normal
			, SUM( CASE WHEN AmortizeType = ''预摊'' THEN AmortizeAmount END) as Pre
			FROM  media.tbs_CostAmortize
			WHERE IsClose = 1
			GROUP BY ContractID
		 ) CAH ON C.ContractID = CAH.ContractID


		---------------------------
		-- A.未回合同处理
		---------------------------
		INSERT INTO #amortize
			( ContractID ,
			  ContractCode ,
			  AmortizeYear ,
			  AmortizeMonth ,
			  AmortizeType ,
			  AmortizeAmount ,
			  Formula
			)

		SELECT C.ContractID
		, C.ContractCode
		, YEAR(@EndDate_TM)
		, MONTH(@EndDate_TM)
		, ''正常''
		, C.ClosedAmountNormal * -1
		, ''合同未回冲回''
		FROM   #basecontract C
		WHERE C.IsSignFinished = 0 AND C.IsAmortized = 1

		UNION ALL

		SELECT C.ContractID
		, C.ContractCode
		, YEAR(M.StartDate)
		, MONTH(M.StartDate)
		, ''正常''
		,  C.RentAmount * media.[GetRangeDays](C.BeginDate, C.EndDate,@DATE_MIN , M.EndDate) /  C.DaysTTL
		, CAST(C.RentAmount AS VARCHAR(20)) + '' ÷ '' + cast(C.DaysTTL AS varchar(20)) + '' × '' + cast(media.[GetRangeDays](C.BeginDate, C.EndDate,@DATE_MIN , M.EndDate) AS varchar(20))
		FROM #basecontract C, #Months M
		WHERE C.IsSignFinished = 0 AND M.SeqNo = 2

		UNION ALL

		SELECT C.ContractID
		, C.ContractCode
		, YEAR(M.StartDate)
		, MONTH(M.StartDate)
		, ''正常''
		, C.RentAmount * media.[GetRangeDays](C.BeginDate, C.EndDate, M.StartDate, M.EndDate) /  C.DaysTTL
		, CAST(C.RentAmount AS VARCHAR(20)) + '' ÷ '' + cast(C.DaysTTL AS varchar(20)) + '' × '' + CAST(media.[GetRangeDays](C.BeginDate, C.EndDate, M.StartDate, M.EndDate) as varchar(20))
		FROM #basecontract C, #Months M
		WHERE C.IsSignFinished = 0 AND M.SeqNo > 2 AND C.EndDate >= M.StartDate

		---------------------------
		-- B.已回合同处理
		---------------------------
		INSERT INTO #amortize
			( ContractID ,
			  ContractCode ,
			  AmortizeYear ,
			  AmortizeMonth ,
			  AmortizeType ,
			  AmortizeAmount ,
			  Formula
			)

		SELECT C.ContractID
			, C.ContractCode
			, YEAR(M.StartDate)
			, MONTH(M.StartDate)
			, ''正常''
			, CASE  WHEN  C.AmortizeType = ''EA134002'' OR C.IsAmortized = 0  THEN
					  C.RentAmount * C.DaysTM / C.DaysTTL  - C.ClosedAmountNormal
					WHEN (C.DaysTTL > C.DaysLM) THEN
					  (C.RentAmount  - C.ClosedAmountNormal) * (C.DaysTM - C.DaysLM) / (C.DaysTTL - C.DaysLM)
					ELSE
					  0
					END
			,  CASE WHEN  C.AmortizeType = ''EA134002'' OR C.IsAmortized = 0  THEN
					  CAST(C.RentAmount AS VARCHAR(20)) + '' ÷ '' + CAST(C.DaysTTL AS VARCHAR(20)) + '' × ''  + CAST(C.DaysTM AS VARCHAR(20)) + '' － ''+ cast(C.ClosedAmountNormal AS varchar(20))
					WHEN (C.DaysTTL > C.DaysLM) THEN
					  ''('' + cast(C.RentAmount as varchar(20)) + '' － '' + cast(C.ClosedAmountNormal as varchar(20)) + '') ÷ ('' + cast(C.DaysTTL as varchar(20)) + '' － '' +  cast(C.DaysLM as varchar(20)) + '') × ('' + cast(C.DaysTM as varchar(20)) + '' － '' + cast(C.DaysLM as varchar(20)) + '')''
					ELSE
					  ''''
					END
		FROM #basecontract C, #Months M
		WHERE C.IsSignFinished = 1 AND M.SeqNo = 1

		UNION ALL

		SELECT C.ContractID
			, C.ContractCode
			, YEAR(M.StartDate)
			, MONTH(M.StartDate)
			, ''正常''
			, CASE  WHEN  C.AmortizeType = ''EA134002'' OR C.IsAmortized = 0 THEN
					  C.RentAmount * media.[GetRangeDays](C.BeginDate, C.EndDate, M.StartDate, M.EndDate) / C.DaysTTL
					WHEN (C.DaysTTL > C.DaysLM) THEN
					  (C.RentAmount  - C.ClosedAmountNormal) * media.[GetRangeDays](C.BeginDate, C.EndDate, M.StartDate, M.EndDate) / (C.DaysTTL - C.DaysLM)
					ELSE
					  0
					END
			, CASE  WHEN  C.AmortizeType = ''EA134002'' OR C.IsAmortized = 0 THEN
					  CAST(C.RentAmount AS VARCHAR(20)) + '' ÷ '' + cast(C.DaysTTL AS varchar(20)) + '' × '' + cast(media.[GetRangeDays](C.BeginDate, C.EndDate, M.StartDate, M.EndDate) AS varchar(20))
					WHEN (C.DaysTTL > C.DaysLM) THEN
					  ''('' + cast(C.RentAmount as varchar(20)) + '' － '' + cast(C.ClosedAmountNormal as varchar(20))  + '') ÷ ('' +  cast(C.DaysTTL as varchar(20)) + '' － '' +  cast(C.DaysLM as varchar(20)) + '') × '' + cast(media.[GetRangeDays](C.BeginDate, C.EndDate, M.StartDate, M.EndDate) as varchar(20))
					ELSE
					  ''''
					END
		FROM #basecontract C, #Months M
		WHERE C.IsSignFinished = 1 AND M.SeqNo > 1 AND C.EndDate >= M.StartDate

		---------------------------
		-- C.取整处理
		---------------------------
			INSERT INTO #amortize
			( ContractID ,
			  ContractCode ,
			  AmortizeYear ,
			  AmortizeMonth ,
			  AmortizeType ,
			  AmortizeAmount ,
			  Formula
			)

		SELECT C.ContractID
			, C.ContractCode
			, CASE WHEN A.YM IS NULL THEN YEAR(@EndDate_TM) ELSE A.YM / 100 END
			, CASE WHEN A.YM IS NULL THEN MONTH(@EndDate_TM) ELSE A.YM % 100 END
			, ''正常''
			, C.RentAmount - ISNULL(A.Amount, 0) - C.ClosedAmountNormal
			, ''取整处理 '' + CAST(C.RentAmount - ISNULL(A.Amount, 0) - C.ClosedAmountNormal  AS VARCHAR(20))
		   FROM #basecontract C
		LEFT JOIN
		(
			SELECT ContractID,  SUM(AmortizeAmount) AS Amount, MAX(AmortizeYear * 100 + AmortizeMonth) AS YM  FROM #amortize
			WHERE AmortizeType = ''正常''
			GROUP BY contractID
		) A ON C.ContractID = A.ContractID
		WHERE C.RentAmount <> (ISNULL(A.Amount, 0) + C.ClosedAmountNormal)

		---------------------------
		-- D.预摊销处理
		---------------------------
		-- D1.冲回
		INSERT INTO #amortize
		( ContractID ,
		  ContractCode ,
		  AmortizeYear ,
		  AmortizeMonth ,
		  AmortizeType ,
		  AmortizeAmount ,
		  Formula
		)

		SELECT C.ContractID 
			, C.ContractCode 
			, YEAR(@EndDate_TM) 
			, MONTH(@EndDate_TM) 
			, ''预摊'' 
			, SUM(AmortizeAmount) * -1 
			, ''冲减在续签(预)摊销''
		FROM media.tbs_CostAmortize CA
		JOIN  #basecontract C ON CA.ContractID = C.ContractID
		WHERE CA.AmortizeType = ''预摊'' 
		AND IsClose = 1
		AND (C.DealStatus = 6 OR C.DealStatus = 9 OR (C.DealStatus = 10 and C.DealSubStatus = 94))
		GROUP BY C.ContractID, C.ContractCode
		HAVING SUM(AmortizeAmount) <> 0

		-- D2.预摊
		INSERT INTO #amortize
		( ContractID ,
		  ContractCode ,
		  AmortizeYear ,
		  AmortizeMonth ,
		  AmortizeType ,
		  AmortizeAmount ,
		  Formula
		)

		SELECT C.ContractID 
			, C.ContractCode 
			, YEAR(@EndDate_TM) 
			, MONTH(@EndDate_TM) 
			, ''预摊''
			, CASE WHEN CAH.Amount > C.MaxAmount180 THEN C.MaxAmount180 - CAH.Amount
				 WHEN C.RentAmount  * DATEDIFF(d, C.EndDate , @EndDate_TM) / C.DaysTTL > C.MaxAmount180 THEN  C.MaxAmount180 - ISNULL(CAH.Amount, 0)
				 ELSE C.RentAmount  * DATEDIFF(d, C.EndDate , @EndDate_TM) / C.DaysTTL - ISNULL(CAH.Amount, 0) END
			, CASE WHEN CAH.Amount > C.MaxAmount180 THEN CAST(C.MaxAmount180 AS VARCHAR(20)) + '' － '' +  CAST(CAH.Amount AS VARCHAR(20))
				 WHEN C.RentAmount  * DATEDIFF(d, C.EndDate , @EndDate_TM) / C.DaysTTL > C.MaxAmount180 THEN CAST(C.MaxAmount180 AS VARCHAR(20)) + '' － '' + CAST(ISNULL(CAH.Amount, 0) AS VARCHAR(20))
				 ELSE CAST(C.RentAmount AS VARCHAR(20)) + '' ÷ '' + CAST(C.DaysTTL  AS VARCHAR(20)) + '' × '' + CAST(DATEDIFF(d, C.EndDate , @EndDate_TM) AS VARCHAR(20)) + '' － '' +  CAST(ISNULL(CAH.Amount, 0) AS VARCHAR(20)) END
		FROM #basecontract C
		LEFT JOIN   (
			SELECT CA.ContractID , SUM(CA.AmortizeAmount) AS Amount FROM media.tbs_CostAmortize CA
			WHERE  CA.IsClose = 1
			AND CA.AmortizeType = ''预摊''
			GROUP BY CA.ContractID
		) CAH ON C.ContractID = CAH.ContractID
		WHERE C.IsSignFinished = 1
		AND C.DealStatus <> 6 AND C.DealStatus <> 9 AND (C.DealStatus <> 10 OR C.DealSubStatus <> 94)
		AND C.EndDate < @EndDate_TM

		DELETE media.tbs_CostAmortize WHERE IsClose = 0

		INSERT INTO media.tbs_CostAmortize
				( ContractID ,
				  ContractCode ,
				  AmortizeYear ,
				  AmortizeMonth ,
				  AmortizeType ,
				  AmortizeAmount ,
				  IsClose ,
				  Formula ,
				  CreateTime ,
				  LastUpdateTime
				)
		SELECT  ContractID ,
				  ContractCode ,
				  AmortizeYear ,
				  AmortizeMonth ,
				  AmortizeType ,
				  AmortizeAmount ,
				  0,
				  Formula ,
				  GETDATE() ,
				  GETDATE()
		FROM #amortize A
		WHERE A.AmortizeAmount <> 0

		DROP TABLE #Months
		DROP TABLE #basecontract
		DROP TABLE #amortize

		SELECT @Result = ''OK''

    END
    else
    IF @StepNo = 3
    BEGIN

	PRINT @EndDate_TM
	
        IF DATEDIFF(d,@WillCloseMonthLastDay, @EndDate_TM) > 0
        BEGIN
            select @Result = CONVERT(VARCHAR(7), @WillCloseMonthLastDay, 120) + ''不是当前会计期间('' + CONVERT(VARCHAR(7), @EndDate_TM, 120) + '')''
        END
        ELSE IF DATEDIFF(d,@WillCloseMonthLastDay, @EndDate_TM) < 0
        BEGIN
            select @Result = CONVERT(VARCHAR(7), @WillCloseMonthLastDay, 120) + ''已经结过帐！''
        END
        ELSE
        BEGIN

		UPDATE PP
		SET PP.ChargePayDate = @BeginDate_NM
		FROM media.tbb_PayPlan PP
		INNER JOIN media.tbb_Contract C ON PP.ContractID = C.ContractID
		WHERE C.IsSignFinished = 0
		AND PP.ValidStatus = 0
		AND PP.PlanPayDate <= @WillCloseMonthLastDay

        INSERT INTO media.tbs_CostAmortize_His
               ( AmortizeID,  ContractID , ContractCode , AmortizeYear , AmortizeMonth , AmortizeType , AmortizeAmount  , AmortizeTime , Formula , CreateTime)
        SELECT  AmortizeID, ContractID , ContractCode , AmortizeYear , AmortizeMonth , AmortizeType , AmortizeAmount , @EndDate_TM , Formula , CreateTime 
        FROM media.tbs_CostAmortize
        WHERE AmortizeYear = YEAR(@EndDate_TM) AND AmortizeMonth = MONTH(@EndDate_TM)

        -- 处理对冲的情况
        INSERT INTO media.tbb_PayPlan_His
                ( PlanPayID , ContractID , VendorID , FeeType , PayKind , PayWay , PlanPayDate , ChargePayDate , PayAmount , PaidAmount , FeeBeginDate , FeeEndDate , HaveInvoice , Memo , ValidStatus , DealStatus , CreateTime)
        SELECT  PP.PlanPayID , PP.ContractID , PP.VendorID , PP.FeeType , PP.PayKind , PP.PayWay , PP.PlanPayDate ,
                ISNULL(PP.ChargePayDate, PP.PlanPayDate) ,
                PP.PayAmount - PP.CloseAmount, PP.PaidAmount , PP.FeeBeginDate , PP.FeeEndDate , PP.HaveInvoice , PP.Memo , PP.ValidStatus , 0 , PP.CreateTime
                FROM media.tbb_PayPlan PP
                JOIN media.tbb_Contract C ON C.ContractID = PP.ContractID
            WHERE C.IsSignFinished = 1  
				AND DATEDIFF(MONTH, ISNULL(PP.ChargePayDate, PP.PlanPayDate), @EndDate_TM) = 0
                AND PP.ValidStatus = 0


		INSERT INTO media.tbb_PayBill_His
		        ( PayBillID ,
		          PlanPayID ,
		          ContractID ,
		          PayAmount ,
		          PayKind ,
		          PayDate ,
		          BalanceNo ,
		          ValidStatus ,
		          ReturnAmount ,
		          CloseAmount ,
		          Memo ,
		          CreateTime ,
		          LastUpdateTime
		        )
		SELECT  PB.PayBillID ,
		PB.PlanPayID ,
		PB.ContractID ,
		PB.PayAmount ,
		PB.PayKind ,
		PB.PayDate ,
		PB.BalanceNo ,
		PB.ValidStatus ,
		PB.ReturnAmount ,
		PB.CloseAmount ,
		PB.Memo ,
		PB.CreateTime ,
		PB.LastUpdateTime FROM  media.tbb_PayBill PB
            JOIN media.tbb_PayPlan PP ON PP.PlanPayID = PB.PlanPayID
         WHERE DATEDIFF(MONTH, @EndDate_TM, PB.PayDate ) = 0
            AND PB.ValidStatus = 0
            AND PP.ValidStatus = 0
            
		INSERT INTO media.tbb_ReturnBill_His
		        ( ReturnBillID ,
		          PayBillID ,
		          ReturnKind ,
		          ReturnAmount ,
		          ReturnDate ,
		          CreateTime,
		          ValidStatus
		        )
			SELECT RB.ReturnBillID, PB.PayBillID, RB.ReturnKind, RB.ReturnAmount, RB.ReturnDate, GETDATE() , 0
			FROM media.tbb_ReturnBill RB
			JOIN media.tbb_PayBill PB ON RB.PayBillID = PB.PayBillID
		    WHERE DATEDIFF(mm, @EndDate_TM, RB.ReturnDate ) = 0
            AND RB.validstatus = 0
            AND PB.validstatus = 0
            
        UPDATE media.tbs_CostAmortize
        SET IsClose = 1
        WHERE AmortizeYear = YEAR(@EndDate_TM)
            AND AmortizeMonth = MONTH(@EndDate_TM)
   
        SELECT @Result = ''OK''

        END

    END
ELSE
IF @StepNo = 4
    BEGIN
	
		IF (DATEDIFF(mm, @WillCloseMonthLastDay, @EndDate_LM) = 0)
		BEGIN
			UPDATE media.tbs_CostAmortize
			SET IsClose = 0
			WHERE AmortizeYear = YEAR(@EndDate_LM)
				AND AmortizeMonth = MONTH(@EndDate_LM)

			DELETE FROM media.tbs_CostAmortize_his
			WHERE AmortizeYear = YEAR(@EndDate_LM) AND AmortizeMonth = MONTH(@EndDate_LM)

			DELETE media.tbb_PayPlan_His WHERE DATEDIFF(MONTH, @EndDate_LM, ChargePayDate) = 0

			DELETE media.tbb_PayBill_His WHERE DATEDIFF(MONTH, @EndDate_LM, PayDate) = 0
	        
			DELETE media.tbb_ReturnBill_His WHERE DATEDIFF(MONTH, @EndDate_LM, ReturnDate) = 0
	        
			SELECT @Result = ''OK''
			
		END
		ELSE 
			SELECT @Result = convert(varchar(7), @WillCloseMonthLastDay, 21) 
                           + ''非最后已结帐会计期间('' + convert(varchar(7), @EndDate_LM, 21) + '')，无法反结帐！''

    END
ELSE
IF @StepNo = 5
BEGIN

    SELECT C.ContractID, C.RentAmount, ISNULL(A.Amount, 0) AS AmortizeAmount, C.RentAmount - ISNULL(A.Amount, 0) AS diff, C.ContractCode
    FROM  media.tbb_Contract C
     LEFT JOIN
     (SELECT CA.ContractID, SUM(CA.AmortizeAmount) AS Amount
      FROM media.tbs_CostAmortize CA
      WHERE CA.AmortizeType = ''正常'' GROUP BY CA.ContractID
     ) A ON C.ContractID = A.ContractID
    WHERE C.RentAmount <> ISNULL(A.Amount, 0)

END


    select @Result as ''Result''





' 
END
GO
