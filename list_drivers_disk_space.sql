DECLARE @svrName VARCHAR(255)
DECLARE @sql VARCHAR(400)
DECLARE @output TABLE (line VARCHAR(255))

--by default it will take the current server name, we can the SET the server name as well

SET @svrName = @@SERVERNAME 
IF CHARINDEX ('\', @svrName) > 0
	SET @svrName = SUBSTRING(@svrName, 1, CHARINDEX('\',@svrName)-1)

SET @sql = 'powershell.exe -c "Get-WmiObject -ComputerName ' + QUOTENAME(@svrName,'''') + ' -Class Win32_Volume -Filter ''DriveType = 3'' | SELECT name,capacity,freespace | foreach{$_.name+''|''+$_.capacity/1048576+''%''+$_.freespace/1048576+''*''}"'

--INSERTing disk name, total space and free space value in to temporary table

INSERT @output
EXEC xp_cmdshell @sql

--script to retrieve the values in MB FROM PS Script output

SELECT RTRIM(LTRIM(SUBSTRING(line,1,CHARINDEX('|',line) -1))) AS drivename
      ,ROUND(CAST(RTRIM(LTRIM(SUBSTRING(line,CHARINDEX('|',line)+1,
      (CHARINDEX('%',line) -1)-CHARINDEX('|',line)) )) AS FLOAT),0) AS 'capacity(MB)'
      ,ROUND(CAST(RTRIM(LTRIM(SUBSTRING(line,CHARINDEX('%',line)+1,
      (CHARINDEX('*',line) -1)-CHARINDEX('%',line)) )) AS FLOAT),0) AS 'freespace(MB)'
      ,CAST (((ROUND(CAST(RTRIM(LTRIM(SUBSTRING(line,CHARINDEX('%',line)+1,
      (CHARINDEX('*',line) -1)-CHARINDEX('%',line)) )) AS FLOAT),0)))*100/
      (ROUND(CAST(RTRIM(LTRIM(SUBSTRING(line,CHARINDEX('|',line)+1,
      (CHARINDEX('%',line) -1)-CHARINDEX('|',line)) )) AS FLOAT),0)) AS INT) AS 'freespace %'
      

FROM @output
WHERE line LIKE '[A-Z][:]%'
ORDER BY drivename
