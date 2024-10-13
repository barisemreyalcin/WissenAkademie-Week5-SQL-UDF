---------------------------------
-- USER DEFINED FUNCTION - UDF --
---------------------------------
-- 1. Scalar: Tek bir deðer döndürür. Klasik function gibi
-- 2. Table Valued: Table gibi bir þey döndürür

-- SCALAR FUNCTION
CREATE FUNCTION dbo.fn_sum
(
	@Num1 int, @Num2 int
)
RETURNS int
AS
BEGIN
	DECLARE @Sum int
	SET @Sum = @Num1 + @Num2
	RETURN @Sum
END

SELECT [dbo].[fn_sum](24, 8) [Sum]
SELECT [dbo].[fn_sum](24, 2) [Sum]
SELECT [dbo].[fn_sum](2, 8) [Sum]

ALTER FUNCTION dbo.fn_concatStr
(
	@Str1 varchar(50), 
	@Str2 varchar(50), 
	@Seperator varchar(1) = ' '
)
RETURNS varchar(100)
AS
BEGIN
	DECLARE @Str varchar(100)
	SET @Str = @Str1 + @Seperator + @Str2
	RETURN @Str
END

SELECT [dbo].[fn_concatStr]('Black', 'Mamba', 'X') String
SELECT [dbo].[fn_concatStr]('Black', 'Mamba', DEFAULT) String

SELECT * FROM Employees
SELECT EmployeeID, [dbo].[fn_concatStr](FirstName, LastName, '-')
FROM Employees

-- Kötü özelliði: Her satýrda fonksiyon çaðrýlýyor

ALTER FUNCTION dbo.fn_factorial
(
	@Num int
)
RETURNS bigint
AS
BEGIN
	DECLARE @i int = 1
	WHILE @Num > 1
	BEGIN
		SET  @i = @Num * @i
		SET  @Num = @Num - 1 
	END
	RETURN @i
END

SELECT [dbo].[fn_factorial](10) FactorialResult

ALTER FUNCTION dbo.fn_RecursiveFactorial
(
	@Num int
)
RETURNS bigint
AS
BEGIN
	DECLARE @Result bigint
	IF @Num <= 1
		SET @Result = 1
	ELSE
		SET @Result = @Num * dbo.fn_RecursiveFactorial(@Num - 1)
	RETURN @Result
END
SELECT [dbo].fn_RecursiveFactorial(5) FactorialResult

----------------------------------
-- TABLE VALUED FUNCTION
-- 1. Inline

CREATE FUNCTION dbo_GetOrdersByCustomer
(
	@CustomerID varchar(5)
)
RETURNS table
AS
RETURN SELECT * FROM Orders
	WHERE
		CASE WHEN @CustomerID = '0' THEN @CustomerID ELSE CustomerID END = @CustomerID

-- SELECT * FROM Employees WHERE 1 = 1 Tüm kayýtlar
-- SELECT * FROM Employees WHERE 1 = 0 Sadece kolon listesi

-- View'den tek farký parametre almasý
SELECT * FROM [dbo].[dbo_GetOrdersByCustomer]('ALFKI')
SELECT * FROM [dbo].[dbo_GetOrdersByCustomer]('VINET')
SELECT * FROM [dbo].[dbo_GetOrdersByCustomer]('0') -- Tüm kayýtlar

-- EmployeeID'ye göre total ciro dönen fonksiyon
CREATE FUNCTION fn_EmployeeTotal
(
	@EmployeeID int
)
RETURNS TABLE
AS
RETURN
	SELECT [dbo].[fn_concatStr](E.FirstName, E.LastName, ' ') EmployeeName,
	SUM(OD.Quantity * OD.UnitPrice * (1 - OD.Discount)) Total
	FROM Orders O INNER JOIN [Order Details] OD ON O.OrderID = OD.OrderID
	INNER JOIN Employees E ON O.EmployeeID = E.EmployeeID
	WHERE E.EmployeeID = @EmployeeID
	GROUP BY O.EmployeeID, E.FirstName, E.LastName

SELECT * FROM [dbo].[fn_EmployeeTotal](4)

-- 2. Multistatement Table-Valued Function
CREATE FUNCTION fn_GetCustomerOrders
(
	@CustomerID varchar(5)
)
RETURNS @CustomerOrders TABLE
(
	-- Döndüreceðim tablonun kolon isimlerini ben veriyorum
	OrderID int,
	OrderDate datetime,
	EmployeeName varchar(100)
	-- Bu tablo DB'de yok ben oluþturuyorum
)
BEGIN
	-- Tablodaki datalarý bunlarla doldur
	INSERT INTO @CustomerOrders
	SELECT O.OrderID, O.OrderDate, E.FirstName + ' ' + E.LastName
	FROM Orders O INNER JOIN Employees E ON O.EmployeeID = E.EmployeeID
	WHERE O.CustomerID = @CustomerID
	
	-- Kayýt varsa ilgili kaydý döndürecek yukardan
	IF @@ROWCOUNT = 0
	BEGIN
		INSERT INTO @CustomerOrders
		VALUES(0, NULL, 'N/A') -- Kayýt yoksa bunu döner
	END 
	RETURN
END

SELECT * FROM  [dbo].[fn_GetCustomerOrders]('VINET')
SELECT * FROM  [dbo].[fn_GetCustomerOrders]('ALFKI')
SELECT * FROM  [dbo].[fn_GetCustomerOrders]('')