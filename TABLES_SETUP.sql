CREATE TYPE BookType AS ENUM ('literature', 'artistic', 'scientific', 'biography', 'professional');
CREATE TYPE GenderType AS ENUM ('female', 'male', 'unknown', 'other');
CREATE TYPE AuthorType AS ENUM ('primary', 'secondary');

CREATE TABLE Library (
	LibraryId SERIAL PRIMARY KEY,
	Name VARCHAR(20),
	OpenTime TIMESTAMP,
	CloseTime TIMESTAMP
);
-- Alter the OpenTime column
ALTER TABLE Library
ALTER COLUMN OpenTime TYPE TIME;

-- Alter the CloseTime column
ALTER TABLE Library
ALTER COLUMN CloseTime TYPE TIME;

--constraint
ALTER TABLE Library
ADD CONSTRAINT check_open_close_time
CHECK (OpenTime < CloseTime);



CREATE TABLE Librarian (
	LibrarianId SERIAL PRIMARY KEY,
	Name VARCHAR (20)
);

CREATE TABLE LibraryLibrarian (
	LibraryId INT REFERENCES Library(LibraryId),
	LibrarianId INT REFERENCES Librarian(LibrarianId),
	PRIMARY KEY(LibraryId, LibrarianId)
);

CREATE TABLE Book (
	BookId SERIAL PRIMARY KEY,
	Name VARCHAR(20),
	Type BookType,
	DateOfRelease TIMESTAMP
);
ALTER TABLE Book
ADD COLUMN Genre VARCHAR(30);

--constraints
ALTER TABLE Book
ADD CONSTRAINT check_release_date
CHECK (DateOfRelease <= CURRENT_TIMESTAMP);

ALTER TABLE Book
ADD CONSTRAINT check_book_type
CHECK (Type IN ('literature', 'artistic', 'scientific', 'biography', 'professional'));


CREATE TABLE BookLibrary (
	BookId INT REFERENCES Book(BookId),
	LibraryId INT REFERENCES Library(LibraryId),
	PRIMARY KEY (BookId, LibraryId)
);

CREATE TABLE Country (
	CountryId SERIAL PRIMARY KEY,
	Name VARCHAR(20),
	Population BIGINT,
	AverageWage INT
);
ALTER TABLE Country
ALTER COLUMN Name TYPE VARCHAR(60);

--constraints
ALTER TABLE Country
ADD CONSTRAINT check_population_non_negative
CHECK (Population >= 0);

ALTER TABLE Country
ADD CONSTRAINT check_average_wage_non_negative
CHECK (AverageWage >= 0);


CREATE TABLE Author (
	AuthorId SERIAL PRIMARY KEY,
	Name VARCHAR(30),
	DateOfBirth TIMESTAMP,
	CountryId INT REFERENCES Country(CountryId),
	Gender GenderType,
	Profit INT
);
ALTER TABLE Author
ADD COLUMN Surname VARCHAR(20);
ALTER TABLE Author
ADD COLUMN DateOfDeath TIMESTAMP;
ALTER TABLE Author
ADD COLUMN Profession VARCHAR(40);
ALTER TABLE Author
DROP COLUMN DateOfDeath;
ALTER TABLE Author
ADD COLUMN Died BOOL;

--constraints
ALTER TABLE Author
ADD CONSTRAINT check_birth_date
CHECK (DateOfBirth <= CURRENT_TIMESTAMP);

ALTER TABLE Author
ADD CONSTRAINT check_gender_type
CHECK (Gender IN ('female', 'male', 'unknown', 'other'));

ALTER TABLE Author
ADD CONSTRAINT check_profit_non_negative
CHECK (Profit >= 0);




CREATE TABLE AuthorBook (
    AuthorId INT REFERENCES Author(AuthorId),
    BookId INT REFERENCES Book(BookId),
    AutorshipType AuthorType,
    PRIMARY KEY (AuthorId, BookId)
);



CREATE TABLE LibraryUser (
	LibraryUserId SERIAL PRIMARY KEY,
	Name VARCHAR (30),
	Debt VARCHAR (30)
);

CREATE TABLE Borrowing (
	BookId INT REFERENCES Book(BookId),
	LibraryUserId INT REFERENCES LibraryUser(LibraryUserId),
	DateOfBorrow TIMESTAMP,
	DateOfReturn TIMESTAMP
);
ALTER TABLE Borrowing 
ADD COLUMN Returned BOOL;
ALTER TABLE Borrowing
ADD CONSTRAINT pk_Borrowing PRIMARY KEY (BookId, LibraryUserId);


--constraints
ALTER TABLE Borrowing
ADD CONSTRAINT check_borrow_date
CHECK (DateOfBorrow <= CURRENT_TIMESTAMP);

ALTER TABLE Borrowing
ADD CONSTRAINT check_return_date
CHECK (DateOfReturn >= DateOfBorrow);

	
