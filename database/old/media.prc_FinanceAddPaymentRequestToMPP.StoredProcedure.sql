IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[media].[prc_FinanceAddPaymentRequestToMPP]') AND type in (N'P', N'PC'))
DROP PROCEDURE [media].[prc_FinanceAddPaymentRequestToMPP]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[media].[prc_FinanceAddPaymentRequestToMPP]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'





--SET QUOTED_IDENTIFIER ON|OFF
--SET ANSI_NULLS ON|OFF

CREATE PROCEDURE [media].[prc_FinanceAddPaymentRequestToMPP]
	@PlanPayID	bigint,
	@AccountBank varchar(100) = null,
	@AccountName varchar(100) = null,
	@AccountNumber varchar(44) = null,
	@PayMethod    VARCHAR(50),
	@BatchID   INT,
	@OperatorId bigint
AS
set nocount on
	
	declare @Result varchar(120)
	declare @ToPay decimal(18, 2)
	declare @ValidStatus int, @n1 int, @n2 int
	declare @PayBillID BIGINT, @ContractID BIGINT
	
	if not exists (select 1 from media.tbb_PayPlan where PlanPayID = @PlanPayID)
	begin
		select @Result = ''未找到对应的应付款''
	end
	else	
	begin	
		select @ToPay = PayAmount - PaidAmount, @ValidStatus = ValidStatus, @ContractID = ContractID
		from media.tbb_PayPlan where PlanPayID = @PlanPayID
		
		if @ValidStatus <> 0 
			begin
				select @Result = ''应付款状态不正确''
			end
		else
		if @ToPay <= 0
			begin
				select @Result = ''支付金额不正确''
			end
		else
			begin
				select @n1 = COUNT(case when (AuditStatus BETWEEN 0 AND 10-1) and ApplyType = 1 then PayBillID end),
				       @n2 = COUNT(case when (AuditStatus BETWEEN 0 AND 10-1) and ApplyType = 2 then PayBillID end)
				from media.tbb_PayApply where PlanPayID = @PlanPayID 
				
				if @n1 > 0
					select @Result = ''请勿重复提交申请''
				else
				if @n2 > 0
					select @Result = ''财务已加入付款计划，无须提交申请''
				else
				
				begin
				
					begin try
						BEGIN TRAN
					 
					 
					 
						INSERT INTO media.tbb_PayApply
						        ( ApplyType ,
						          ApplyDate ,
						          ApplyUserID ,
						          PlanPayID ,
						          ContractID ,
						          ApplyBatchID ,
						          PayAmount ,
						          PayKind ,
						          AuditStatus ,
						          AuditTime ,
						          AuditUserID ,
						          Memo ,
						          CreateTime ,
						          LastUpdateTime
						        )
						VALUES  ( 2 , -- ApplyType - int 财务用
						          DATEADD(dd, DATEDIFF(d, 0, GETDATE()), 0) , -- ApplyDate - date
						          @OperatorId , -- ApplyUserID - bigint
						          @PlanPayID , -- PlanPayID - bigint
						          @ContractID , -- ContractID - bigint
						          @BatchID , -- ApplyBatchID - bigint
						          @ToPay , -- PayAmount - decimal
						          @PayMethod , -- PayKind - varchar(50)
						          0 , -- AuditStatus - int
						          NULL , -- AuditTime - datetime
						          NULL , -- AuditUserID - bigint
						          '''' , -- Memo - varchar(200)
						          GETDATE() , -- CreateTime - datetime
						          GETDATE()  -- LastUpdateTime - datetime
						        )
					 
						select @PayBillID = @@IDENTITY

						-- 插入付款帐号表

						 INSERT INTO [media].[tbi_PayAccount]
								   ([PayBillID]
								   ,[BankSubjectID]
								   ,[AccountBank]
								   ,[AccountName]
								   ,[AccountNumber]
								   ,[CreateTime]
								   ,[LastUpdateTime])
							 VALUES
								   (@PayBillID
								   ,null
								   ,@AccountBank
								   ,@AccountName
								   ,@AccountNumber
								   ,GETDATE()
								   ,GETDATE())  
								  
						UPDATE media.tbb_ApplyBatch 
						SET ApplyAmount += @ToPay 
							, LastUpdateTime = GETDATE()
						WHERE ApplyBatchID = @BatchID
														
						COMMIT TRAN
						select @Result = ''OK''
					end try
					
					
					begin catch
						rollback tran
						select @Result = ''插入付款申请表失败''
					end catch;
              
				end
			end
	end
	
	select @Result as ''Result''
' 
END
GO
