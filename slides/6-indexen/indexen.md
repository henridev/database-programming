# indexen and performance

## introduction

dichotomy:

moore's law <=> wirths law

![sql server database](https://techyaz.com/wp-content/uploads/2017/07/Page-Extent-1024x576.jpg)

![extend types](https://docs.microsoft.com/en-us/sql/relational-databases/media/extents.gif?view=sql-server-ver15)

![](https://res.cloudinary.com/dri8yyakb/image/upload/v1641409922/67F9A5EB-B4CE-42AB-8ED6-ED327E924BB6_yndwyk.png)



- for logging (.ldf) and data (.mdf (maset database file), .ndf) => uses **Random Access Files**
- space allocation
  - **page** = 8kb block of contiguous space
  - **extent** = 8 logical consecutive pages (basic unit in which space is managed)
    - **uniform** = used for one db-object
    - **mixed** = shared by max 8 different db-objects
  - new tables start in mixed extent
  - **extension** > 8 pages: in uniform extent

[docs](https://docs.microsoft.com/en-us/previous-versions/sql/sql-server-2008-r2/ms190969)

### terms

- **Heap** = *unordered collection of data pages without clustered index, default storage of a table*
- **IAM (index allocation map)** = *page that keeps track of the pages assigned to a single allocation unit* (you can find the table in extent x, y ...)
- **Table Scan** = *when a query has too fetch all pages of the table*
- **Clustered Index** = *the structure that includes index pages and base table data*
- **Clustered Index Seek** = *the process whereby a query navigates through the clustered index tree to the base data-table*
- **Non Clustered Index** = *the structure that includes index pages but instead of having base table data as leaf nodes it has pointers (RIDs or clustered index key values) to the base data*

## creating / removing indexes

```SQL
CREATE [UNIQUE] [ | NONCLUSTERED]
INDEX index_name ON table (kolom [,...n])
```

- `UNIQUE` => all value in indexed column should be unique
- table can be empty or filled when index is defined
- columns in unique index need `NOT NULL` constraint

```SQL
DROP INDEX table_name.index [,...n]
```

## Search types

### table scan

```SQL
CREATE TABLE dbo.PhoneBook
(
    LastName varchar(50) NOT NULL
    FirstName varchar(50) NOT NULL
    PhoneNumber varchar(50) NOT NULL
)
```

**Heap** => unordered collection of data pages without clustered index, default storage of a table  

- when new values are inserted they get added where there is space in no specific order
- **IAM** => a page that keeps track of the pages assigned to a single allocation unit
- **table scan** => when a query has too fetch all pages of the table

- problems with heaps
  - inefficiency => it requires table scans and fetching all rows for a query is inefficient 
  - fragmentation => table gets scattered over multiple non consecutive pages
  - forward pointers => when a variable length raw eg. varchar gets longer on update a page is added which will make table scans even slower
- pros of heaps
  - efficiency => table scans can be usefull when a lot of data need to be fetched

### clustered

> with a heap we saved unordered so looking things up will be inefficient. A first step to take could be to order the data physically then at least we will now when to stop. From this point on we can go a step further with clustered indexes. this will generate a set of index pages that will allow us to perform queries via clustered index seek instead of table scans. 
> above the base table data we add a **btree** of index pages to speed up searches

![clustered index tree](https://res.cloudinary.com/dri8yyakb/image/upload/v1641281005/BF88BB4F-0440-46D2-A06B-1D566D99BBA7_g12woo.png)



- ex. arrange phonebook data physically by lastname then firstname this time we will know when to stop scanning
- SQLServer will then build **index pages** based on the physical order which allow queries to navigate directly to the looked for data => this entire structure (index pages + base table data) = **clustered index**
- **clustered index seek** = when a query navigates through the clustered index tree to the base table data
- **index pages** tell you range of lastnames on each pages
- **clustered index** contains base data itself => you can maximum one **clustered index** => impossible to structure same data in 2 different ways without having to duplicate it (**)

```SQL
SELECT PhoneNumber
FROM dbo.PhoneBook
WHERE 
    LastName = 'Evans' AND
    FistName = 'John'
```

> by default a tables PK will be used to create the clustered index

### non-clustered

> is a physically seperate structure that references / points to the base data and it can have a different sort order

![non clustered index](https://res.cloudinary.com/dri8yyakb/image/upload/v1641281464/ED59EC6B-A6D6-4DED-B5DC-8D19D86E9A43_gwkmin.png)

- (**) solution
- creates a separate physical structure with same tree like clustered index except base data won't be leaf of tree now instead we use **pointers/references** back to base data => any index key order can be used because it is independent from base table data order
- where to find actual records? 
  - base data in **heap** => the base data in it is referenced via **RID's** (row ids) / physical locations of row in table
  - base data exists in **clustered index** => the base data in it is referenced via **clustered index key/values** (key lookup)

- **scan/seek** same as with clustered indexes but data directly available can be limited because non-clustered indexes usually only include a *subset* of column from the table => if columns are requested that are not in the index => query will navigate to base data via **references**

```SQL
CREATE NONCLUSTERED INDEX IX_PhoneBook_NCI
ON dbo.PhoneBook(LastName, FirstName)
WHERE (LastName >= 'Burnett')
```

> **filtered indexes** = only contain rows that meet a  user-defined predicate, and to create these, you have to add a WHERE clause to the index definition
>
> ! clustered indexes cannot be filtered because they require all the data

![filtered indexes](https://res.cloudinary.com/dri8yyakb/image/upload/v1641282375/359BC025-EDFC-4186-A0AB-2FBF54931986_mittd7.png)

```SQL
CREATE NONCLUSTERED INDEX IX_PhoneBook_NCI
ON dbo.PhoneBook(LastName, FirstName)
INCLUDE (PhoneNumber)
```

> **include columns** = add copies of non-key column values to the leaf level of the index tree
>
> including this can prevent a lookup in the heap via **RID** 

![include columns](https://res.cloudinary.com/dri8yyakb/image/upload/v1641282364/29E44938-1989-4421-B136-D0C593DB3CD6_w7qejk.png)

- queries using the nonclustered index won't have to the expense of navigating back to the base data to get those non-key column values
- in **clustered** indexes `INCLUDE` columns aren't used because it will need all columns either way

## checking the search strategy

```sql
SELECT * FROM Employee1
SELECT * FROM Employee2

-- employee 2 is a copy of 1 without the indexes
```

when we select the queries and press `ctrl+l` a **query execution plan** get calculated. Here this plan shows that in both cases a table scan gets used



![table scan](https://res.cloudinary.com/dri8yyakb/image/upload/v1641409147/B8F16872-5192-43B9-8AE7-4AA84BBD62A6_pdttbn.png)



```sql
SELECT * FROM Employee1 WHERE lastname = 'King'
SELECT * FROM Employee2 WHERE lastname = 'King'
```

here it is clear that because of the index on index seek is performed for Employee1, and 98% of the time a look up in the heap took place. the difference here remains small however 54% time vs 46% time



<img src="https://res.cloudinary.com/dri8yyakb/image/upload/v1641409395/5F6D599C-6BB8-42D4-A0F5-0D10A83B4FDD_zktuvk.png" style="zoom:67%;" />

```sql
SELECT lastname FROM Employee1
SELECT lastname FROM Employee2
```

in this case the query is 5 times faster however

![](https://res.cloudinary.com/dri8yyakb/image/upload/v1641409636/9D4848EC-B30C-4441-B958-0E34A0D64B9E_ydd7b4.png)



```sql
SELECT * FROM Customers
```

here all the data is in the clustered index scan



![](https://res.cloudinary.com/dri8yyakb/image/upload/v1641409824/8048066C-BCF2-4490-BD4A-507D449DBC59_yshevl.png)

## focus on indexes

- What?
  - ordered structure imposed on table records
  - searching inside a b-tree is `log(n)`
- Why?
  - faster data retrieval
  - forced row unicity
- Why not?
  - indexes => need more storage
  - can slow down `ALTER,DELETE,INSERT` because indexes need to be adjusted too

> library analogy:
>
> - catalogue = index pages
> - location = pointer to data
> - book = row
> - catalogue drawers = btree



### determining index usage => SQL optimizer

#### sql optimizer

- module in DBMS
- analyses + rephrases SQL commands 
- picks best strategy for index used based on stats about table size, table use, data distribution
- searching in SQL is also used for fields in `where, group by, having, order by` and `joined` fields (not only in a `select`)

### clustered index 

![index](https://res.cloudinary.com/dri8yyakb/image/upload/v1641447283/838388C9-7FC9-4F63-BEF3-F32D5B38863D_qyhgnp.png)

![example clustered index](https://res.cloudinary.com/dri8yyakb/image/upload/v1641447406/7DB761FB-78B9-4A26-9280-759C8A706D00_atcwia.png)

- physical record order = order in clustered index
- each table has max one clustered index
- requires unique values and PK constraint
- thanks to the **double linked list** order is ensured when reading sequential records => no need for **forward pointers**



### non clustered index

![non clustered index](https://res.cloudinary.com/dri8yyakb/image/upload/v1641447872/6235136F-2A17-42C5-9E2C-B64EAAFC0F61_wmriqp.png)

![non clustered index example](https://res.cloudinary.com/dri8yyakb/image/upload/v1641447860/9CEE2F6F-1549-4E51-8B5A-D133FC4491FC_jr1ywe.png)

- work with **pointers** to find base data
  - RID lookup if base data stored in Heap
  - Key lookup if base data stored in clustered index
- default index
- +1 per table
- forward and backwards pointers between **leaf nodes**
- if more fields are needed than present in index these need to be fetched from data pages



### covering index

- a form of **non clustered index** containing all columns needed for a query
- will step over the **key lookup / RID lookup** because these are included in the leaves of the index next to the key values or RID 
- included columns are *not* indexed themselves

#### example

 each index has only one field

![indexes one column](https://res.cloudinary.com/dri8yyakb/image/upload/v1641448325/9F48DE96-5B19-4667-BBA9-0E90D89334CF_fzpqzq.png)

```sql
SELECT lastname FROM Employee1 WHERE lastname = 'Duffy'
SELECT lastname, title FROM Employee1 WHERE lastname = 'Duffy'
```

![](https://res.cloudinary.com/dri8yyakb/image/upload/v1641448332/25CEB4DA-F578-4496-9B53-4AF1BB9E2D51_jbkb6l.png)

when only looking for lastname by lastname we can get by by only using an **index seek via non clustered index**

when we also want to get data outside our index column a **key lookup** or **rid lookup** will be necessary



```sql
create nonclustered index EmpLastName_Incl_Title 
ON Employee1(lastname) INCLUDE (title);

SELECT lastname FROM Employee1 WHERE lastname = 'Duffy'
SELECT lastname, title FROM Employee1 WHERE lastname = 'Duffy'
```

thanks to the inclusion of last name no RID lookup is necessary this time 



![no rid needed non clustered index](https://res.cloudinary.com/dri8yyakb/image/upload/v1641448332/25CEB4DA-F578-4496-9B53-4AF1BB9E2D51_jbkb6l.png)

## when to use what



we can't tell what is better 1 index with +1 column or 2 indexes with 1 column => depends on queries

```sql
CREATE NONCLUSTERED INDEX EmpLastName ON Employee1(lastname);
-- +
CREATE NONCLUSTERED INDEX EmpFirstname ON Employee1(firstname);
-- OR?
CREATE NONCLUSTERED INDEX EmpLastNameFirstname ON Employee1(lastname, firstname)
```

```sql
SELECT lastname, firstname FROM Employee1
WHERE firstname = 'Chris';
```

if we have multiple indexes with one column => we will need index seek to find firstname then rid lookup for lastname



![index seek to find firstname then rid for lastname](https://res.cloudinary.com/dri8yyakb/image/upload/v1641448962/49CF7A79-DADE-49D5-9D61-3671429CA672_ss0mz3.png)

- When querying (eg. in WHERE-clause) only 2nd and or  3th, ... field of index, the index is not used. This directly  follows from the B-tree table structure of the composed  index (eg if you index on lastname then firstname but only search by firstname the index will be useless)
- indexes should be based on your queries

```sql
CREATE NONCLUSTERED INDEX EmpLastName ON Employee1(lastname);
-- +
CREATE NONCLUSTERED INDEX EmpFirstname ON Employee1(firstname);
-- OR?
CREATE NONCLUSTERED INDEX EmpLastNameFirstname ON Employee1(lastname, firstname)

-- Test: Only combined index on lastname and firstname
DROP INDEX EmpLastName ON Employee1;

SELECT lastname, firstname FROM Employee1
WHERE lastname = 'Preston'

SELECT lastname, firstname FROM Employee1
WHERE firstname = 'Chris';

```

![](https://res.cloudinary.com/dri8yyakb/image/upload/v1641449457/75422D05-DCB0-432A-A9BE-5D06CAABCC9D_wior74.png)

in the first one the index `EmpLastNameFirstname` is chosen which only requires a index seek

in the second query `EmpFirstname` is used as index because in the where clause firstname is used then however we don't have the lastname yet so RID lookup is needed 



```sql
-- With extra index on firstname and covering of  lastname
create nonclustered index EmpFirstnameIncLastname 
ON employee1(firstname)
INCLUDE (lastname);

SELECT lastname, firstname FROM Employee1
WHERE lastname = 'Preston'

SELECT lastname, firstname FROM Employee1
WHERE firstname = 'Chris';

```

![include lastname](https://res.cloudinary.com/dri8yyakb/image/upload/v1641449757/62EFC19D-EBDA-4D7E-BFDE-2868E62C1989_pss8qk.png)

we can make the RID lookup redundant by adding an include lastname to the index

### when not to use an index

- rarely used columns 
- columns with small number of possible values eg M F => only two intermediary nodes in btree => close to sequential seek
- columns in small tables
- columns type bit, image, text ..



### where influencing search efficiency 

![](http://3.bp.blogspot.com/-_QhfI3eCe9o/Ut-3oP225TI/AAAAAAAAECY/64yN2G3oLLQ/s1600/scanvsseekscreenshot.jpg)

```sql
SELECT lastname, firstname 
FROM Employee1
WHERE lastname = 'Preston'

-- we perform on operation on the column in the WHERE clause
-- btree cant be used corretly we will need to use a inde xscan
SELECT lastname, firstname 
FROM Employee1
WHERE SUBSTRING(lastname, 2, 1) = 'r'

-- btree cant be used corretly we will need to use a scan
SELECT lastname, firstname 
FROM Employee1
WHERE lastname LIKE '%r%'

```

![](https://res.cloudinary.com/dri8yyakb/image/upload/v1641449744/CEB18EFC-4485-44B1-A4F1-73BACF156CF2_tko1ch.png)

- **index scan** = index is used but it is scanned until all searched records are found
- **index seek** = tree structure of index is used = fast data retrieval



## tips & tricks

1. avoid functions
2. avoid calculations => isolate columns
3. prefer `outer join` above `union`
4. avoid `any` and `all`



#### 1

```sql
-- BAD --> uses index scan
SELECT FirstName, LastName, Birthdate
FROM Employee1
WHERE Year(BirthDate) = 1980;
-- GOOD --> uses index seek
SELECT FirstName, LastName, Birthdate
FROM Employee1
WHERE BirthDate >= '1980-01-01' AND
BirthDate < '1981-01-01';

-- BAD
SELECT LastName
FROM Employee1
WHERE substring(LastName,1,1) = 'D';
-- GOOD
SELECT LastName
FROM Employee1
WHERE LastName like 'D%';
```

![](https://res.cloudinary.com/dri8yyakb/image/upload/v1641451087/0F89C219-3CF7-4ABA-9E40-33BB88B0EDCF_dmac7q.png)

![](https://res.cloudinary.com/dri8yyakb/image/upload/v1641451197/88593750-53D1-4905-A06B-D059381EFDF8_hvclzv.png)

### 2

```sql
-- BAD 
SELECT EmployeeID, FirstName, LastName
FROM Employee1
WHERE Salary*1.10 > 100000;
-- GOOD calculate on value instead of column
SELECT EmployeeID, FirstName, LastName
FROM Employee1
WHERE Salary > 100000/1.10;
```

<img src="https://res.cloudinary.com/dri8yyakb/image/upload/v1641451380/C41D38B8-3ED6-4BA5-AFCC-45ADB205A0A9_gvi4ng.png" style="zoom:67%;" />

<img src="https://res.cloudinary.com/dri8yyakb/image/upload/v1641451376/69BFD534-3D33-4D67-B931-E066F40C5C76_g1wxxx.png" style="zoom:50%;" />

### 3

```sql
-- BAD 
SELECT lastname, firstname, orderid
from Employee1 e join Orders o on e.EmployeeID = o.employeeid
union
select lastname, firstname, null
from Employee1 
where EmployeeID not in (select EmployeeID from Orders)
-- GOOD
SELECT lastname, firstname, orderid
from Employee1 e left join Orders o on e.EmployeeID = o.employeeid;
```

![](https://res.cloudinary.com/dri8yyakb/image/upload/v1641451466/704B4E52-851A-44A9-86DD-45E344F259B6_mneisc.png)

### 4

```sql
-- BAD 
SELECT lastname, firstname, birthdate
from Employee1 
where BirthDate >= all(select BirthDate from Employee1)
-- GOOD
SELECT lastname, firstname, birthdate
from Employee1 
where BirthDate = (select max(BirthDate) from Employee1)
```

![](https://res.cloudinary.com/dri8yyakb/image/upload/v1641451595/EECBF05B-1E8F-41C8-A9B1-DDE772826A78_o7jtet.png)