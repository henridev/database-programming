create table parts
(super char(3) not null,
sub char(3) not null,
number integer not null,
primary key (super,sub));

INSERT into parts values ('O1','O2',10);
INSERT into parts values ('O1','O3',5);
INSERT into parts values ('O1','O4',10);
INSERT into parts values ('O2','O5',25);
INSERT into parts values ('O2','O6',5);
INSERT into parts values ('O3','O7',10);
INSERT into parts values ('O6','O8',15);
INSERT into parts values ('O8','O11',5);
INSERT into parts values ('O9','O10',20);
INSERT into parts values ('O10','O11',25);