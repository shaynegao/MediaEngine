IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[media].[prc_FinancePay]') AND type in (N'P', N'PC'))
DROP PROCEDURE [media].[prc_FinancePay]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[media].[prc_FinancePay]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'

create procedure [media].[prc_FinancePay] @PayBillID  bigint,
     @PayKind    varchar(20),
     @StatementNo varchar(100),
     @BankSubjectID [int],
     @PayDate    datetime,
     @PayAmount  decimal(10,2),
     @OperatorId bigint as
begin
    declare @Result varchar(120)
    declare @PlanPayID BIGINT, @ContractID BIGINT
    declare @AuditStatus int
    declare @payBillCount int
    declare @PlanPayAmount decimal(10,2), @PlanPaidAmount decimal(10,2)
    
    -- check
    -- 1. 检查付款是否存在
    if not exists (select 1 from [media].tbb_PayApply where PayBillID = @PayBillID)
        select @Result = ''未找到对应的付款申请''
    else
    begin
        select @PlanPayID = PlanPayID, @AuditStatus = AuditStatus, @ContractID = ContractID 
        from [media].tbb_PayApply where PayBillID = @PayBillID
        
        select @PlanPayAmount = PayAmount, @PlanPaidAmount = PaidAmount 
        from media.tbb_PayPlan where PlanPayID = @PlanPayID and ValidStatus = 0
        
        if @PlanPayID is null
            select @Result = ''未找到对应的应付款''
        else
        if @AuditStatus <> 1
            select @Result = ''应付款未审核''
        else
        if @PayAmount <> @PlanPayAmount - @PlanPaidAmount
        begin
            select @Result = ''付款金额不正确''
        end
        else
            begin
                begin try
                    BEGIN TRAN
						-- 更新付款申请表
						UPDATE media.tbb_PayApply
						SET AuditStatus = 2                            
						,[LastUpdateTime] = GETDATE()
                        where PayBillID = @PayBillID
                                       
                        -- 插入付款表
                        INSERT INTO media.tbb_PayBill	
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
                        VALUES  ( @PayBillID , -- PayBillID - bigint
                                  @PlanPayID , -- PlanPayID - bigint
                                  @ContractID , -- ContractID - bigint
                                  @PayAmount , -- PayAmount - decimal
                                  @PayKind , -- PayKind - varchar(50)
                                  @PayDate , -- PayDate - date
                                  @StatementNo , -- BalanceNo - varchar(20)
                                  0 , -- ValidStatus - int
                                  0 , -- ReturnAmount - decimal
                                  0 , -- CloseAmount - decimal
                                  '''' , -- Memo - varchar(200)
                                  GETDATE() , -- CreateTime - datetime
                                  GETDATE()  -- LastUpdateTime - datetime
                                )

                        -- 更新应付表
                        update media.tbb_PayPlan
                        set PaidAmount = PaidAmount + @PayAmount
                        , LastUpdateTime = getdate()
                        where PlanPayID = @PlanPayID
                        
                        -- 插入付款帐号表
                        update [media].[tbi_PayAccount]
						SET [BankSubjectID] = @BankSubjectID
                        WHERE PayBillID = PayBillID
                        
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
