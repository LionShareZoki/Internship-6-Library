--Selet name, surname, gender, country name and average wage of each author
SELECT
    a.Name AS "AuthorName",
    CASE
        WHEN a.Gender = 'male' THEN 'MUŠKI'
        WHEN a.Gender = 'female' THEN 'ŽENSKI'
        WHEN a.Gender = 'unknown' THEN 'NEPOZNATO'
        ELSE 'OSTALO'
    END AS "Gender",
    c.Name AS "CountryName",
    c.AverageWage AS "AverageWage"
FROM
    Author a
JOIN
    Country c ON a.CountryId = c.CountryId;

--Name and date of release of every sfientific book together with the names of primary authors
--that have worked on it, where names of the authors have to be in one cell and in a form of a Surname N.
--Example Puljak I.
SELECT
    b.Name AS "BookName",
    b.DateOfRelease,
    string_agg(concat_ws(' ', a.Name, substr(a.Surname, 1, 1) || '.'), ', ') AS "PrimaryAuthors"
FROM
    Book b
JOIN
    AuthorBook ab ON b.BookId = ab.BookId
JOIN
    Author a ON ab.AuthorId = a.AuthorId
WHERE
    b.Type = 'scientific' AND ab.AutorshipType = 'primary'
GROUP BY
    b.BookId, b.Name, b.DateOfRelease;


--All the combinations (BookNames) of books and borrows  in december 2023.
--In case that book has never been borrowed show it once and on borrow cell 
--It should say null
WITH AllBookTitles AS (
    SELECT DISTINCT BookId, Name
    FROM Book
)
SELECT 
    abt.Name AS BookTitle, 
    CASE 
        WHEN DATE_PART('month', b.DateOfBorrow) = 12 AND DATE_PART('year', b.DateOfBorrow) = 2023 THEN b.DateOfBorrow
        ELSE NULL 
    END AS DateOfBorrow
FROM 
    AllBookTitles abt
    LEFT JOIN Borrowing b ON abt.BookId = b.BookId
ORDER BY 
    abt.Name;


--Top 3 Libraries with the biggest number of books

SELECT l.Name, COUNT(BookLibrary.BookId) AS BookCount
FROM Library l
JOIN BookLibrary ON l.LibraryId = BookLibrary.LibraryId 
GROUP BY l.LibraryId, l.Name
ORDER BY BookCount DESC
LIMIT 3;







--By each book the number of people that have borrowed at least once

SELECT
    b.BookId,
    b.Name AS BookName,
    COUNT(DISTINCT br.LibraryUserId) AS NumberOfBorrowers
FROM
    Book b
LEFT JOIN
    Borrowing br ON b.BookId = br.BookId
GROUP BY
    b.BookId, b.Name
ORDER BY
    b.BookId;



s--Names of all the users that have a borrowed book right now

SELECT lu.name
From LibraryUser lu
JOIN Borrowing b ON lu.LibraryUserId = b.LibraryUserId
WHERE DateOfBorrow <= NOW() AND DateOfReturn > NOW();





-- All the authors that had their book released between 2019.-2022.

Select DISTINCT a.Name 
FROM Author a
JOIN AuthorBook ab ON a.AuthorId = ab.AuthorId
JOIN Book b ON ab.BookID = b.BookId
WHERE EXTRACT(YEAR FROM b.DateOfRelease) BETWEEN 2019 AND 2022;


--Name of country and number of artistic books by each country 
--If the two authors are from the same country it is being counted as one book
--Where the countries are sorted by the number of alive authors from biggest
-- to the smallest

SELECT 
    c.Name AS CountryName, 
    COUNT(DISTINCT b.BookId) AS NumberOfArtisticBooks,
    alive_authors.NumberOfAliveAuthors
FROM 
    Country c
    JOIN Author a ON c.CountryId = a.CountryId
    JOIN AuthorBook ab ON a.AuthorId = ab.AuthorId
    JOIN Book b ON ab.BookId = b.BookId
    LEFT JOIN (
        SELECT 
            CountryId, 
            COUNT(DISTINCT AuthorId) AS NumberOfAliveAuthors
        FROM 
            Author
        WHERE 
            Died IS FALSE OR Died IS NULL
        GROUP BY 
            CountryId
    ) AS alive_authors ON c.CountryId = alive_authors.CountryId
WHERE 
    b.Type = 'artistic'
GROUP BY 
    c.Name, alive_authors.NumberOfAliveAuthors
ORDER BY 
    alive_authors.NumberOfAliveAuthors DESC;



--By each combination of authors and genres (If it exists) number of borrows 
--of the books in that genre
SELECT
    a.Name AS AuthorName,
    b.Genre,
    COUNT(DISTINCT bor.BookId) AS NumberOfBorrowings
FROM Author a
JOIN AuthorBook ab ON a.AuthorId = ab.AuthorId
JOIN Book b ON ab.BookId = b.BookId
LEFT JOIN Borrowing bor ON b.BookId = bor.BookId
GROUP BY a.Name, b.Genre
ORDER BY a.Name, b.Genre;




--By every member how much he owes because of being late,
--In case he doesnt owe anything write out "CLEAN"
SELECT
    lu.Name,
    CASE
        WHEN lu.Debt = '0' OR lu.Debt IS NULL THEN 'CLEAN'
        ELSE lu.Debt
    END AS DebtStatus
FROM
    LibraryUser lu;





--Author and name of his first published book 
-- Author and name of his first published book
SELECT a.Name AS AuthorName, MIN(b.Name) AS FirstPublishedBook
FROM Author a
JOIN AuthorBook ab ON a.AuthorId = ab.AuthorId
JOIN Book b ON ab.BookId = b.BookId
GROUP BY a.AuthorId, a.Name
ORDER BY a.AuthorId;

--Country and name of the second released book of that country
WITH RankedBooks AS (
    SELECT
        c.Name AS CountryName,
        b.Name AS BookName,
        b.DateOfRelease,
        ROW_NUMBER() OVER (PARTITION BY c.CountryId ORDER BY b.DateOfRelease) AS ReleaseRank
    FROM 
        Country c
        JOIN Author a ON c.CountryId = a.CountryId
        JOIN AuthorBook ab ON a.AuthorId = ab.AuthorId
        JOIN Book b ON ab.BookId = b.BookId
)
SELECT
    CountryName,
    BookName AS SecondReleasedBook
FROM 
    RankedBooks
WHERE 
    ReleaseRank = 2;




--Books and number of active borrows, where those with less than 10 active borrows are not shown
SELECT b.BookId, b.Name AS BookName, COUNT(borrow.BookId) AS ActiveBorrowCount
FROM Book b
LEFT JOIN Borrowing borrow ON b.BookId = borrow.BookId
WHERE NOW() >= borrow.DateOfBorrow AND COALESCE(borrow.Returned, false) = false
GROUP BY b.BookId
HAVING COUNT(borrow.BookId) >= 10
ORDER BY ActiveBorrowCount DESC;



--The average number of borrows by the piece of book by each Country
SELECT c.CountryId, c.Name AS CountryName, AVG(borrows_per_book) AS AvgBorrowsPerBook
FROM Country c
JOIN Author a ON c.CountryId = a.CountryId
JOIN AuthorBook ab ON a.AuthorId = ab.AuthorId
JOIN Book b ON ab.BookId = b.BookId
JOIN BookLibrary bl ON b.BookId = bl.BookId
LEFT JOIN (
    SELECT bl.BookId, COUNT(*) AS borrows_per_book
    FROM Borrowing bor
    JOIN BookLibrary bl ON bor.BookId = bl.BookId
    GROUP BY bl.BookId
) AS subquery ON b.BookId = subquery.BookId
GROUP BY c.CountryId, c.Name
ORDER BY AvgBorrowsPerBook DESC;





--The number of authors (which have published more than 5 books) 
--By the profession, decade of birth and gender
--In case that number of authors is less than 10, dont show category
--Sort the view by the decade of birth
WITH AuthorStats AS (
    SELECT
        a.Profession,
        EXTRACT(DECADE FROM a.DateOfBirth) AS BirthDecade,
        a.Gender,
        COUNT(DISTINCT ab.BookId) AS PublishedBooksCount
    FROM Author a
    JOIN AuthorBook ab ON a.AuthorId = ab.AuthorId
    GROUP BY a.Profession, EXTRACT(DECADE FROM a.DateOfBirth), a.Gender
    HAVING COUNT(DISTINCT ab.BookId) > 5
)
SELECT
    Profession,
    BirthDecade,
    Gender,
    COUNT(*) AS AuthorCount
FROM AuthorStats
GROUP BY BirthDecade, Gender, Profession
HAVING COUNT(*) >= 10
ORDER BY BirthDecade;


-------------
--10 richest authors, if by each book he gets root of number of copies divided by number of author by book
SELECT
    a.AuthorId,
    a.Name AS AuthorName,
    a.Profession,
    SUM(SQRT(bl.NumCopies / ab.AuthorCount)) AS AuthorWealth
FROM
    Author a
JOIN (
    SELECT ab.AuthorId, COUNT(DISTINCT ab.BookId) AS AuthorCount
    FROM AuthorBook ab
    GROUP BY ab.AuthorId
) AS ab ON a.AuthorId = ab.AuthorId
JOIN AuthorBook ab2 ON a.AuthorId = ab2.AuthorId
JOIN Book b ON ab2.BookId = b.BookId
JOIN (
    SELECT bl.BookId,  COUNT(*) AS NumCopies
    FROM BookLibrary bl
    JOIN Borrowing bor ON bl.BookId = bor.BookId
    WHERE bor.Returned = FALSE
    GROUP BY bl.BookId
) AS bl ON b.BookId = bl.BookId
GROUP BY a.AuthorId, a.Name, a.Profession
ORDER BY AuthorWealth DESC
LIMIT 10;



-- Procedure for borrowing a book
CREATE OR REPLACE PROCEDURE BorrowBook(
    p_bookId INT,
    p_libraryUserId INT,
    p_dueDate DATE DEFAULT (CURRENT_DATE + INTERVAL '20 days')
) LANGUAGE plpgsql AS $$
BEGIN
    -- Check if the book exists and is available for borrowing
    IF NOT EXISTS (SELECT 1 FROM Book WHERE BookId = p_bookId) THEN
        RAISE EXCEPTION 'The book with ID % does not exist.', p_bookId;
    END IF;

    IF EXISTS (
        SELECT 1 FROM Borrowing
        WHERE BookId = p_bookId AND LibraryUserId = p_libraryUserId AND Returned = FALSE
    ) THEN
        RAISE EXCEPTION 'The book is already borrowed by the user.';
    END IF;

    -- Insert a new borrowing record
    INSERT INTO Borrowing (BookId, LibraryUserId, DateOfBorrow, DateOfReturn, Returned)
    VALUES (p_bookId, p_libraryUserId, CURRENT_TIMESTAMP, p_dueDate, FALSE);

    -- Display a confirmation message
    RAISE NOTICE 'The book with ID % has been successfully borrowed. The due date is %.', p_bookId, p_dueDate;
END;
$$;



--Procedure test example
CALL BorrowBook(201, 1);
