IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[media].[prc_FinanceVerifyInvoice]') AND type in (N'P', N'PC'))
DROP PROCEDURE [media].[prc_FinanceVerifyInvoice]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[media].[prc_FinanceVerifyInvoice]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'



-- =============================================    
-- Author:  gaoweiwei    
-- Create date: 2013-06-07    
-- Description: 审核发票
-- Return Value:
--				 OK
CREATE proc [media].[prc_FinanceVerifyInvoice]
	@InvoiceIDs  varchar(2000),
	@Items  varchar(8000), 

	@UserID               bigint

as
begin
	declare @Result varchar(120)
	declare @InvoiceCount int, @InvoiceCountDb int
	declare @InvoiceCountType int
	declare @PaymentCount int, @PaymentCountDb int, @RefundCount int, @RefundCountDb int
	declare @InvoiceAmount decimal(10,2), @PaymentAmount decimal(10,2), @RefundAmount decimal(10,2)
	declare @OverflowA int, @OverflowB int
	declare @xml_hndl int 
	declare @VerifyId bigint
	
	set @Result = ''''
	 
	create table #t_Invoice (InvoiceID  bigint)
	create table #t_Payment (PaymentID  bigint, amount decimal(10,2))
	create table #t_Refund (RefundID  bigint, amount decimal(10,2))
	
	insert #t_Invoice (InvoiceID)
	select a from [media].[f_split](@InvoiceIDs, '','')
	
	select @InvoiceCount = COUNT(*) from #t_Invoice
	
	select @InvoiceCountDb = COUNT(*), @InvoiceAmount = SUM(I.InvoiceAmount), @InvoiceCountType = COUNT(distinct I.invoiceType) from [media].[tbb_Invoice] I
	join #t_Invoice TI on I.InvoiceID = TI.InvoiceID
	where I.VerifyID = 0
	
	if (@InvoiceCountType <> 1)
	begin
		select @Result = ''发票只能同一种类型''
	end
	else
	if (@InvoiceCountDb <> @InvoiceCount)
	begin
		select @Result = ''发票已发生修改，请重新关联''
	end
	
	
	--prepare the XML Document by executing a system stored procedure
	exec sp_xml_preparedocument @xml_hndl OUTPUT, @Items 
	
	insert into #t_Payment (PaymentID, amount)
	Select IDToInsert,Amount
	From
        OPENXML(@xml_hndl, ''/items/payment'', 1)
        With
                    (
                    IDToInsert int ''@id'',
                    Amount decimal(10,2) ''@amount''
                    )
    
    
    
    select @PaymentCount = COUNT(*) from #t_Payment
    
    if (@PaymentCount > 0)
    begin
    
	select @PaymentCountDb = COUNT(*), @PaymentAmount = SUM(P.amount), @OverflowA = sum(case when (P.amount - PB.PayAmount + PB.CloseAmount) > 0 then 1 else 0 end)
	from media.tbb_PayBill PB
	join #t_Payment P on P.PaymentID = PB.PayBillID
 
		if (@PaymentCount <> @PaymentCountDb)
			select @Result = ''付款已发生修改，请重新关联''
		else 
		if (@OverflowA > 0)
			select @Result = ''开票金额超出''

    end
    
                   
    insert into #t_Refund (RefundID, amount)
	Select IDToInsert,Amount
	From
        OPENXML(@xml_hndl, ''/items/Refund'', 1)
        With
                    (
                    IDToInsert int ''@id'',
                    Amount decimal(10,2) ''@amount''
                    )

	
	
    select @RefundCount = COUNT(*) from #t_Refund
    
    if (@Result = '''' and @RefundCount > 0)
    begin
    
	select @RefundCountDb = COUNT(*), @RefundAmount = SUM(R.amount), @OverflowB = sum(case when (R.amount - RB.ReturnAmount + RB.CloseAmount) > 0 then 1 else 0 end)
	from media.tbb_ReturnBill RB
	join #t_Refund R on R.RefundID = RB.ReturnBillID
 
		if (@RefundCount <> @RefundCountDb)
			select @Result = ''付款已发生修改，请重新关联''
		else 
		if (@OverflowB > 0)
			select @Result = ''开票金额超出''

    end
	
	
	if (@Result = '''')
	begin
		if @InvoiceAmount <> (@PaymentAmount + @RefundAmount)
			select @Result = ''开票金额与已付款金额合计不一致''
		else
			begin
				begin try
					BEGIN TRAN
						INSERT INTO [media].[tbb_VerifyInvoice]
								   ([VerifyAmount]
								   ,[InvoiceCount]
								   ,[PayBillCount]
								   ,[ReturnBillCount]
								   ,[CreateTime]
								   ,[LastUpdateTime])
							 VALUES
								   (@InvoiceAmount
								   ,@InvoiceCount
								   ,@PaymentCount
								   ,@RefundCount
								   ,GETDATE()
								   ,GETDATE())

						select @VerifyId = @@IDENTITY
						
						
						-- TODO 
						-- insert tbb_Bill_Invoice 

						update I
						set I.verifyid = @VerifyId
						from [media].[tbb_Invoice] I
						join #t_Invoice TI on I.InvoiceID = TI.InvoiceID
						
						if @@rowcount <> @InvoiceCount
						begin
							   RAISERROR (''@@rowcount <> @InvoiceCount'', -- Message text.
							   16, -- Severity.
							   1 -- State.
							   );
						end		
						
						update PB
						set PB.CloseAmount = PB.CloseAmount + P.amount
						from media.tbb_PayBill PB
						join #t_Payment P on P.PaymentID = PB.PayBillID
						
						if @@rowcount <> @PaymentCount
						begin
							   RAISERROR (''@@rowcount <> @PaymentCount'', -- Message text.
							   16, -- Severity.
							   1 -- State.
							   );
						end	
						
						update RB
						set RB.CloseAmount = RB.CloseAmount + R.amount
						from media.tbb_ReturnBill RB
						join #t_Refund R on R.RefundID = RB.ReturnBillID
						
						if @@rowcount <> @RefundCount
						begin
							   RAISERROR (''@@rowcount <> @RefundCount'', -- Message text.
							   16, -- Severity.
							   1 -- State.
							   );
						end		
						
				COMMIT TRAN
				select @Result = ''OK''

		    end try
		    
		    begin catch
				rollback tran
				select @Result = ''更新时发生异常''
		    end catch;
			end
		
	end
	
	
	select @Result as ''Result''
	
	
end







' 
END
GO
