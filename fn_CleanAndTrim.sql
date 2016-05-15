IF OBJECT_ID('dbo.fn_CleanAndTrim') IS NULL
    EXEC ('CREATE FUNCTION dbo.fn_CleanAndTrim () RETURNS INT AS BEGIN RETURN 0 END')
GO
-- =============================================
-- Author: Nate Johnson
-- Source: http://stackoverflow.com/posts/24068265
-- Description: TRIMs a string 'for real' - removes standard whitespace from ends,
-- and replaces ASCII-char's 9-13, which are tab, line-feed, vert tab, form-feed,
-- & carriage-return (respectively), with a whitespace or specified character(s).
-- Option "@PurgeReplaceCharsAtEnds" determines whether or not to remove extra head/tail
-- replacement-chars from the string after doing the initial replacements.
-- This is only truly useful if you're replacing the special-chars with something
-- **OTHER** than a space, because plain LTRIM/RTRIM will have already removed those.
-- =============================================
ALTER FUNCTION dbo.[fn_CleanAndTrim] (
    @Str NVARCHAR(MAX)
    , @ReplaceTabWith NVARCHAR(5) = ' '
    , @ReplaceNewlineWith NVARCHAR(5) = ' '
    , @PurgeReplaceCharsAtEnds BIT = 1
)
RETURNS NVARCHAR(MAX) AS
BEGIN
    DECLARE @Result NVARCHAR(MAX)

    --The main work (trim & initial replacements)
    SET @Result = LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
        LTRIM(RTRIM(@Str))  --Basic trim
        , NCHAR(9), @ReplaceTabWith), NCHAR(11), @ReplaceTabWith)   --Replace tab & vertical-tab
        , (NCHAR(13) + NCHAR(10)), @ReplaceNewlineWith) --Replace "Windows" linebreak (CR+LF)
        , NCHAR(10), @ReplaceNewlineWith), NCHAR(12), @ReplaceNewlineWith), NCHAR(13), @ReplaceNewlineWith)))   --Replace other newlines

    --If asked to trim replacement-char's from the ends & they're not both whitespaces
    IF (@PurgeReplaceCharsAtEnds = 1 AND NOT (@ReplaceTabWith = N' ' AND @ReplaceNewlineWith = N' '))
    BEGIN
        --Purge from head of string (beginning)
        WHILE (LEFT(@Result, DATALENGTH(@ReplaceTabWith)/2) = @ReplaceTabWith)
            SET @Result = SUBSTRING(@Result, DATALENGTH(@ReplaceTabWith)/2 + 1, DATALENGTH(@Result)/2)

        WHILE (LEFT(@Result, DATALENGTH(@ReplaceNewlineWith)/2) = @ReplaceNewlineWith)
            SET @Result = SUBSTRING(@Result, DATALENGTH(@ReplaceNewlineWith)/2 + 1, DATALENGTH(@Result)/2)

        --Purge from tail of string (end)
        WHILE (RIGHT(@Result, DATALENGTH(@ReplaceTabWith)/2) = @ReplaceTabWith)
            SET @Result = SUBSTRING(@Result, 1, DATALENGTH(@Result)/2 - DATALENGTH(@ReplaceTabWith)/2)

        WHILE (RIGHT(@Result, DATALENGTH(@ReplaceNewlineWith)/2) = @ReplaceNewlineWith)
            SET @Result = SUBSTRING(@Result, 1, DATALENGTH(@Result)/2 - DATALENGTH(@ReplaceNewlineWith)/2)
    END

    RETURN @Result
END
GO
