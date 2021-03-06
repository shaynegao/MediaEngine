IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[media].[prc_FinanceCurrentPeriod]') AND type in (N'P', N'PC'))
DROP PROCEDURE [media].[prc_FinanceCurrentPeriod]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[media].[prc_FinanceCurrentPeriod]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'



-- =============================================    
-- Author:  gaoweiwei    
-- Create date: 2013-03-25    
-- Description: 得到当前会计期间
-- Return Value: 当前会计期间为已结帐日期加1天，默认为本月
CREATE proc [media].[prc_FinanceCurrentPeriod]
(
	@CurrentBegin datetime output
)
as
begin

	DECLARE @ym INT, @year INT, @month int

	SELECT @ym = MAX(AmortizeYear *100 + AmortizeMonth) FROM  media.tbs_CostAmortize
	WHERE isclose = 1

	IF @ym IS NULL
	BEGIN
		SELECT @CurrentBegin = null
	END
	ELSE
	BEGIN
		SET @year = @ym /100
		SET @month = @ym % 100
		
		IF (@month + 1) = 13
		BEGIN
			select @year = @year + 1, @month = 1
		END
		ELSE
		BEGIN
			select @month = @month + 1
		END
		
		SELECT @CurrentBegin = CAST((@year * 10000 + @month * 100 + 1) AS VARCHAR(8))
	END

	
end




' 
END
GO
