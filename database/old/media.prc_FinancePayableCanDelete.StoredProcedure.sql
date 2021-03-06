IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[media].[prc_FinancePayableCanDelete]') AND type in (N'P', N'PC'))
DROP PROCEDURE [media].[prc_FinancePayableCanDelete]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[media].[prc_FinancePayableCanDelete]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'
CREATE PROCEDURE [media].[prc_FinancePayableCanDelete]
(
	@PayableID BIGINT
)
AS
	DECLARE @Result varchar(120)
	
	IF (EXISTS (SELECT 1 FROM media.tbb_PayApply WHERE PlanPayID = @PayableID AND AuditStatus IN (0,1,2)))
		-- 除开无效的
		SELECT @Result = ''已付款或正在付款流程中''
	ELSE IF  (EXISTS (SELECT 1 FROM media.tbb_PayPlan_His WHERE PlanPayID = @PayableID))
		SELECT @Result = ''已导出应付款凭证''
	ELSE 
		SELECT @Result = ''OK''

	SELECT @Result AS ''Result''  


' 
END
GO
