# user defined functions

- SP => iets doen (stukje code naam geven) => exec sp (groter belang wat er gebeurd)
- (built-in/UD)F => f(something) => something (groter belang voor return)

```SQL
CREATE FUNCTION GetAge(@birthdate as DATE, @eventdate as DATE)
RETURNS INT
AS
BEGIN
	RETURN (
		DATEDIFF(year, @birthdate, @eventdate) -
		CASE 
			WHEN 100 * MONTH(@eventdate) + DAY(@eventdate) < 100 * MONTH(@birthdate) + DAY(@birthdate)
			THEN 1 
			ELSE 0
		)
	END
END
```

```SQL
SELECT lastname, firstname, birthdate, GETDATE() as today, dbo.GetAge(bi)
```
