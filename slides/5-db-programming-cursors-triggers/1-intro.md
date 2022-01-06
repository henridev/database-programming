# Intro Database programming

## 1. How the relational model has been extended to support advanced database application = PSM

- originaly SQL wasn't a complete programming language
  - it could however be embedded in conventional languages
- Later PSM were added to sql which brought procedural programming to SQL
  - variables / constants / datatypes
  - operators
  - control structures
  - procedurs / functions
  - exception handlers

## 2. PSM (persistent stored moduels)

includes **stored procedures** and **stored functions**

examples:

- Transact SQL => sql server
- PL (programmable logic) /SQL => Orqvle
- SQL PL => DB2

> procedural extensions are vendor specific (**propietary languages**) so migrating RDBMS becomes harder once you use them

why use PSM?

- previously PSM used to be more performant than using conventional programming languages
- this however is not the case any longer

Pros:

- modularity: queries can be stored in SP and reused in 3GL
- automatisation: triggers can execute SQL automaticaly
- security:
  - excludes direct queries on tables
  - SP limit what's allowed
  - input parameters avoid SQL injection attacks
- central administration of DB code

Cons:

- reduced scalability: business logic and db processing on the same server => risk for bottlenecks
- vendor lock in
  - non standard syntax
- two programming languages to maintain ex transact SQL and sql server
- two debug environments
- SP/UDF (user defined functions) => have limited OO support
