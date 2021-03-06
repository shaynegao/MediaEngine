IF OBJECT_ID('[media].[prc_FinanceAddPaymentRequest]') IS NOT NULL
	DROP PROCEDURE [media].[prc_FinanceAddPaymentRequest]
GO


CREATE proc [media].[prc_FinanceAddPaymentRequest]
    @PayableID  bigint,
    @AccountBank varchar(100) = null,
    @AccountName varchar(100) = null,
    @AccountNumber varchar(44) = null,
    @PayMethod    VARCHAR(50),
    @UseDeposit BIT = 0 ,
    @OperatorId bigint
as
begin
    set nocount on

    declare @Result varchar(120)
    declare @ToPay decimal(18, 2)
    declare @ValidStatus int, @n1 int, @n2 int
    declare @PayBillID BIGINT, @ContractID BIGINT

    if not exists (select 1 from media.tbb_PayPlan where PlanPayID = @PayableID)
    begin
        select @Result = '未找到对应的应付款'
    end
    else
    if not exists (select 1 from media.tbb_PayPlan PP
            join media.tbb_Contract C on PP.ContractID = C.ContractID
            where PP.PlanPayID = @PayableID and C.OperatorID = @OperatorId AND C.DealStatus IN (3, 10))
    begin
        select @Result = '当前合同状态不允许申请付款'

    end
    else
    begin
        select @ToPay = PayAmount - PaidAmount - CloseAmount, @ValidStatus = ValidStatus, @ContractID = ContractID
        from media.tbb_PayPlan where PlanPayID = @PayableID

        if @ValidStatus <> 0
            begin
                select @Result = '应付款状态不正确'
            end
        else
        if @ToPay <= 0
            begin
                select @Result = '支付金额不正确'
            end
        ELSE
            begin
                select @n1 = COUNT(case when AuditStatus IN (0,1) and ApplyType = 1 then PayBillID end),
                       @n2 = COUNT(case when AuditStatus IN (0,1) and ApplyType = 2 then PayBillID end)
                from media.tbb_PayApply where PlanPayID = @PayableID

                if @n1 > 0
                  begin
                    select '请勿重复提交申请' as 'Result'
                    return
                  end
                if @n2 > 0
                  begin
                    select '财务已加入付款计划，无须提交申请' as 'Result'
                    return
                  end
                IF @UseDeposit = 1
                    BEGIN
                        DECLARE @AvailDeposit DECIMAL(18, 6)
                        
                        SELECT @AvailDeposit =   
                             (DM.DepositAmount + DM.TransferInAmount)
                              - DM.ReturnAmount 
                              - DM.TransferOutAmount 
                              - DM.DamageAmount 
                              - DM.DeductionAmount 
                     FROM media.tbb_DepositMain DM
                        JOIN (
                            SELECT PP.VendorID, C.ContractID, C.PayCompanyID FROM media.tbb_PayPlan PP
                            JOIN media.tbb_Contract C ON PP.ContractID = C.ContractID
                            WHERE PP.PlanPayID = @PayableID
                        ) P ON DM.ContractID = P.ContractID AND DM.PayCompanyID = P.PayCompanyID AND DM.VendorID = P.VendorID
                         
                        
                        IF @AvailDeposit IS NULL  OR @AvailDeposit <= 0
                        BEGIN
                            select '未找到可用的押金' as 'Result'
                            return
                        END
                        ELSE IF @AvailDeposit < @ToPay
                        BEGIN
                            select '可用的押金不足' as 'Result'
                            return
                        END
                        
                        SELECT @PayMethod = 'BM004008'          
                    END

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
                    VALUES  ( 1 , -- ApplyType - int
                              GETDATE() , -- ApplyDate - date
                              @OperatorId , -- ApplyUserID - bigint
                              @PayableID , -- PlanPayID - bigint
                              @ContractID , -- ContractID - bigint
                              NULL , -- ApplyBatchID - bigint
                              @ToPay , -- PayAmount - decimal
                              @PayMethod , -- PayKind - varchar(50)
                              0 , -- AuditStatus - int
                              NULL, -- AuditTime - datetime
                              NULL , -- AuditUserID - bigint
                              '' , -- Memo - varchar(200)
                              GETDATE() , -- CreateTime - datetime
                              GETDATE()  -- LastUpdateTime - datetime
                            )


                    select @PayBillID = @@IDENTITY

                    -- 插入付款帐号表
                    IF @PayMethod <> 'BM004008'
                    BEGIN
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
                    END        

                    COMMIT TRAN
                    select @Result = 'OK'
                end try


                begin catch
                    rollback tran
                    select @Result = '插入付款申请表失败'
                end catch;

       
            end
    end

    select @Result as 'Result'

end





















GO

