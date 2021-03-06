IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[media].[prc_FinanceCreateInvoiceBundle]') AND type in (N'P', N'PC'))
DROP PROCEDURE [media].[prc_FinanceCreateInvoiceBundle]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[media].[prc_FinanceCreateInvoiceBundle]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'

create procedure [media].[prc_FinanceCreateInvoiceBundle] @InvoiceType  varchar(50),
     @VerifyAmount decimal(10, 2),
     @InvoiceCount int,
     @PayBillCount int,
     @ReturnBillCount  int,
     @VendorName VARCHAR(105),
     @Bundle       varchar(6000),
     @Memo         varchar(200) = '''',
     @OperatorId   bigint as
BEGIN
	SET NOCOUNT ON 
	
	declare @Result varchar(120)
    declare @InvoiceID BIGINT
    DECLARE @VerifyID BIGINT
    declare @xml_hndl INT
    
	DECLARE		@InvoiceCode varchar(100)
	DECLARE      @InvoiceAmount decimal(10,2)
	DECLARE     @ReceiveDate datetime
	DECLARE     @TaxAmount decimal(10,2)
	DECLARE     @TaxRate decimal(5,2)

    create table #Invoice
    (
        InvoiceCode varchar(100),
        InvoiceAmount decimal(10, 2),
        ReceiveDate datetime,
        TaxAmount  decimal(10, 2),
        TaxRate  decimal(5, 2)
    )
    
    create table #Payment
    (
        PaymentID BIGINT,
        Amount  decimal(10, 2)
    )
    
    create table #Refund
    (
        RefundID BIGINT,
        Amount  decimal(10, 2)
    )

    --BEGIN TRAN

        INSERT INTO media.tbb_VerifyInvoice ( VerifyAmount , InvoiceCount , PayBillCount , ReturnBillCount , CreateTime , LastUpdateTime )
        VALUES  ( @VerifyAmount , @InvoiceCount , @PayBillCount , @ReturnBillCount , GETDATE() , GETDATE() )

        select @VerifyID = @@IDENTITY

        exec sp_xml_preparedocument @xml_hndl OUTPUT, @Bundle
        
        INSERT INTO #Invoice (InvoiceCode,InvoiceAmount, ReceiveDate, TaxAmount, TaxRate)
		SELECT InvoiceCode,InvoiceAmount, ReceiveDate, TaxAmount, TaxRate
        FROM   
			OPENXML(@xml_hndl, ''/bundle/invoices/invoice'', 1)
			With
                    (
						InvoiceCode VARCHAR(100),
						InvoiceAmount decimal(10,2),
						ReceiveDate DATETIME,
						TaxAmount decimal(10,2),
						TaxRate decimal(5,2)
                    )
                    
        INSERT INTO #Payment( PaymentID, Amount )
		SELECT PaymentID, Amount
        FROM   
			OPENXML(@xml_hndl, ''/bundle/payments/payment'', 1)
			With
                    (
						PaymentID BIGINT,
						Amount decimal(10,2)
                    )                    
                    

        INSERT INTO #Refund( RefundID, Amount )
		SELECT RefundID, Amount
        FROM   
			OPENXML(@xml_hndl, ''/bundle/refunds/refund'', 1)
			With
                    (
						RefundID BIGINT,
						Amount decimal(10,2)
                    )   
                    
		EXEC sp_xml_removedocument @xml_hndl

		-- SELECT * FROM #Invoice
		-- SELECT * FROM #Payment
		-- SELECT * FROM #Refund
		
		DECLARE C CURSOR FAST_FORWARD FOR
		SELECT  InvoiceCode ,
		        InvoiceAmount ,
		        ReceiveDate ,
		        TaxAmount ,
		        TaxRate FROM #Invoice ORDER BY InvoiceCode;

		OPEN C

		FETCH NEXT FROM C INTO @InvoiceCode ,
		        @InvoiceAmount ,
		        @ReceiveDate ,
		        @TaxAmount ,
		        @TaxRate;

		WHILE @@fetch_status = 0
		BEGIN
		  
		  INSERT INTO media.tbb_Invoice
		        ( VerifyID ,
		          InvoiceType ,
		          InvoiceCode ,
		          InvoiceNo ,
		          InvoiceAmount ,
		          VendorName ,
		          ReceiveDate ,
		          InvoiceStatus ,
		          CreatorID ,
		          CreateTime ,
		          LastUpdateTime
		        )
		VALUES  ( @VerifyID,
		          @InvoiceType ,
		          @InvoiceCode , -- InvoiceCode - varchar(100)
		          '''' , -- InvoiceNo - varchar(100)
		          @InvoiceAmount , -- InvoiceAmount - decimal
		          @VendorName , -- VendorName - varchar(105)
		          @ReceiveDate , -- ReceiveDate - date
		          0 , -- InvoiceStatus - int
		          @OperatorId , -- CreatorID - bigint
		          GETDATE() , -- CreateTime - datetime
		          GETDATE()  -- LastUpdateTime - datetime
		        )
		  
		  SELECT @InvoiceID = @@IDENTITY
		  IF @InvoiceType = ''VAT_INVOICE''
		  BEGIN
		  	 INSERT INTO [media].[tbi_InvoiceTaxes]
			   ([InvoiceID]
			   ,[TaxAmount]
			   ,[TaxRate]
			   ,[CreateTime])
			VALUES
			   (@InvoiceID
			   ,@TaxAmount
			   ,@TaxRate
			   ,GETDATE())
		  END
		  
		  

		  FETCH NEXT FROM C INTO @InvoiceCode ,
		        @InvoiceAmount ,
		        @ReceiveDate ,
		        @TaxAmount ,
		        @TaxRate;
		END

	
		CLOSE C;
		DEALLOCATE C;

		INSERT INTO media.tbb_Bill_Invoice
		        ( BillID ,
		          BillType ,
		          VerifyID ,
		          CloseAmount ,
		          Memo ,
		          CreateTime ,
		          LastUpdateTime
		        )
		SELECT  PaymentID, 0, @VerifyID, Amount, @Memo, GETDATE(), GETDATE() 
		FROM #Payment
		
		INSERT INTO media.tbb_Bill_Invoice
		        ( BillID ,
		          BillType ,
		          VerifyID ,
		          CloseAmount ,
		          Memo ,
		          CreateTime ,
		          LastUpdateTime
		        )
		SELECT  RefundID, 1, @VerifyID, Amount, '''', GETDATE(), GETDATE() 
		FROM #Refund	 

		
		
		DROP TABLE #Invoice
		DROP TABLE #Payment
		DROP TABLE #Refund


    --COMMIT TRAN


    --ROLLBACK TRAN
		SET NOCOUNT OFF 

	SELECT @Result = CAST(@VerifyID AS VARCHAR(10))
	
    select @Result as ''Result''
		


end
' 
END
GO
