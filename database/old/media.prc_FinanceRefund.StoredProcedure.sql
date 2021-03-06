IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[media].[prc_FinanceRefund]') AND type in (N'P', N'PC'))
DROP PROCEDURE [media].[prc_FinanceRefund]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[media].[prc_FinanceRefund]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'

create procedure [media].[prc_FinanceRefund] @PaymentID	bigint,		-- 付款单ID
  	@Amount		decimal(10,2),	-- 金额
  	@RefundDate datetime,	-- 退款日期
  	@RefundKind varchar(20),	-- 退款形式
  	@AccountID   bigint = null,
  	@Reason		VARCHAR(200) = '''',
  	@RefundBankName VARCHAR(200),	
  	@RefundName VARCHAR(200),	
  	@RefundAccountNumber  VARCHAR(200),	
  		                      
  	@OperatorId bigint as
begin
	declare @Result varchar(120)
	declare @AuditStatus int
	declare @PlanPayID BIGINT, @ReturnBillID BIGINT
	declare @PayAmount decimal(10,2), @ReturnAmount decimal(10,2)
	declare @PayDate datetime
	 
	if not exists (select * from media.tbb_PayBill where PayBillID = @PaymentID)
		select @Result = ''未找到对应的付款记录''
	else
	begin
	
		select @PlanPayID = PlanPayID, @PayAmount = PayAmount, @PayDate = paydate, 
			@AuditStatus = ValidStatus, @ReturnAmount = ReturnAmount 
		from media.tbb_PayBill where PayBillID = @PaymentID

		if @AuditStatus <> 10
			select @Result = ''付款记录必须为已付款状态''
		else
		if (DATEDIFF(d, @PayDate, @RefundDate) < 0)
			select @Result = ''退款日期不能早于付款日期''
		else
		if @Amount > @PayAmount - @ReturnAmount
		begin
			select @Result = ''退款金额累加不能超出'' + cast(@PayAmount as varchar(20))
		end
		else
	    begin
		    begin try
				BEGIN TRAN
					-- 1. 插入退款表
		    		INSERT INTO [media].[tbb_ReturnBill]
		            ([PayBillID] ,[ReturnKind] ,[ReturnAmount] ,[ReturnDate] ,validstatus , ReturnReason, [CreateTime] ,[LastUpdateTime]) 
		            VALUES
		            (@PaymentID ,@RefundKind ,@Amount ,@RefundDate ,10 , @Reason, GETDATE() ,GETDATE())
		            
		            SELECT @ReturnBillID = @@identity
		            
		            INSERT INTO media.tbi_ReturnAccount
		                    ( ReturnBillID ,
		                      AccountBank ,
		                      AccountName ,
		                      AccountNumber ,
		                      CreateTime ,
		                      LastUpdateTime
		                    )
		            VALUES  ( @ReturnBillID
		                      ,@RefundBankName
		                      ,@RefundName
		                      ,@RefundAccountNumber
		                      ,GETDATE()
		                      ,GETDATE()
		                    )
		            
		            -- 2. 更新付款单
				    UPDATE [media].[tbb_PayBill]
					SET [ReturnAmount] = [ReturnAmount] + @Amount
				      ,[LastUpdateTime] = getdate()
					WHERE PayBillID = @PaymentID
		    		-- 3. 更新应付单
				    UPDATE [media].[tbb_PayPlan]
				    SET [PaidAmount] = [PaidAmount] - @Amount
				      ,[LastUpdateTime] = getdate()
				    WHERE PlanPayID = @PlanPayID
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
