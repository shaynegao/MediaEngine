IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[media].[prc_FinancePaymentRequestAudit]') AND type in (N'P', N'PC'))
DROP PROCEDURE [media].[prc_FinancePaymentRequestAudit]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[media].[prc_FinancePaymentRequestAudit]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'

-- =============================================    
-- Author:  gaoweiwei    
-- Create date: 2013-05-15    
-- Description: 付款申请审核
-- Return Value:
--				 OK
--				 付款申请审核失败
CREATE proc [media].[prc_FinancePaymentRequestAudit]
	@PaymentRequestID	bigint,
	@OperatorId			bigint,
	@IsPass             BIT,
	@Memo				varchar(200)
as
begin
	set nocount on
	
	declare @Result varchar(120)
	declare @PlanPayID bigint
    declare @AuditStatus INT
    declare @NewAuditStatus INT
    
	SELECT @NewAuditStatus = CASE WHEN @IsPass = 1 THEN 1 ELSE 3 END 
    
    SELECT @PlanPayID = PlanPayID, @AuditStatus = AuditStatus FROM  media.tbb_PayApply
    WHERE PayBillID = @PaymentRequestID
    
    -- 1. 检查付款是否存在
    if @PlanPayID IS NULL
        select @Result = ''未找到对应的付款申请''
    else
    begin
		if not exists (select 1 from media.tbb_PayPlan where PlanPayID = @PlanPayID)
		begin
			select @Result = ''未找到对应的应付款''
		end
		else
		if @AuditStatus = 0	 -- 0:待审核
		BEGIN
			IF @IsPass = 1
			BEGIN
				begin tran
				update [media].tbb_PayApply
				set [AuditStatus] = @NewAuditStatus
				, Memo = @Memo
				, AuditTime = GETDATE()
				, AuditUserID = @OperatorId
				, LastUpdateTime = GETDATE()
				where PayBillID = @PaymentRequestID 
				
				if @@ROWCOUNT = 1
				begin
					select @Result = ''OK''
					COMMIT TRAN
				end
				else
				begin
					rollback tran
					select @Result = ''更新付款申请表失败''
				end	
			END
		end
		else
		begin
			select @Result = ''付款申请状态异常''
		end
	end
	
	select @Result as ''Result''
           
end


' 
END
GO
