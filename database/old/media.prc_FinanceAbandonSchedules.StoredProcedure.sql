IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[media].[prc_FinanceAbandonSchedules]') AND type in (N'P', N'PC'))
DROP PROCEDURE [media].[prc_FinanceAbandonSchedules]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[media].[prc_FinanceAbandonSchedules]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'

create procedure [media].[prc_FinanceAbandonSchedules] (
 	@ContractId bigint,
 	@OperatorId int,
 	@Memo varchar(200)
 	
 ) as
begin

		update PB
		set PB.ValidStatus = -1,
		PB.Memo = @Memo
		from media.tbb_PayBill PB
		where PB.ContractID = @ContractId
		 and PB.ValidStatus <> -1 
	
end
' 
END
GO
