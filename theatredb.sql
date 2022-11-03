drop database if exists TheatreRoyal;
create database TheatreRoyal;
use TheatreRoyal;


create table User (
	userID INT PRIMARY KEY auto_increment,
	emailAddress VARCHAR(50) NOT NULL,
	password VARCHAR(50) NOT NULL,
	DOB date not null,
	homeAddress varchar(100) not null,
    constraint emailconst check (emailAddress like '%_@__%.__%')
    -- constraint will be added for password based on client requirements
);

create table PerformanceType(
	performanceTypeID INT PRIMARY KEY auto_increment,
	performanceTypeName VARCHAR(30),
    	constraint typeName check (performanceTypeName in ('opera', 'concert', 'musical', 'theatre'))
);

create table Purchase(
	purchaseID int primary key auto_increment,
    userID int,
    foreign key (userID) references User(userID),
    quantity int
);

create table Ticket(
    ticketID int primary key auto_increment,
    purchaseID int,
    performanceTimingID int,
    ticketPrice decimal(5, 2),
    foreign key (PurchaseID) references Purchase(purchaseID)
);

create table Language(
	languageID INT PRIMARY KEY auto_increment,
	languageOption VARCHAR(30)
);

create table Performance(
	    performanceID int primary key auto_increment,
    	performanceTypeID INT,
     	languageID int,
    	foreign key (performanceTypeID) references PerformanceType(performanceTypeID),
    	foreign key (languageID) references Language(languageID),
    	title varchar(100),
    	description varchar(1000),
    	hasLiveMusic boolean,
	    imageUrl varchar(10000)
	    constraint urlCheck check (imageUrl like '%http_%')
);

create table PerformanceTiming(
	performanceTimingID INT PRIMARY KEY auto_increment,
	performanceID INT,
	dateTimeOfPerformance DATETIME,
	duration TIME,
	foreign key (performanceID) references performance(performanceID) on delete cascade

);

create table SeatTypePrice(
    seatTypePriceID INT AUTO_INCREMENT primary key,
    performanceTimingID INT,
    seatType VARCHAR(100),
	  constraint seatType check (seatType in ('stalls', 'circle')),
    seatAmount INT,
    seatPrice decimal(5,2),
    foreign key (performanceTimingID) references PerformanceTiming(performanceTimingID)
);

-- procedures for inserting data into tables
delimiter / 
create procedure insertUser
				(in aEmailAddress varchar(50), in aPassword varchar(50), in aDOB date, in aAddress varchar(100))
	begin
        insert into User (emailAddress, password, DOB, homeAddress) values (aEmailAddress, aPassword, aDOB, aAddress);
	end; 
/

create procedure insertPerformanceType (in aPerformanceTypeName varchar(30))
	begin
		insert into PerformanceType(performanceTypeName) values (aPerformanceTypeName);
	end;
/

create procedure insertLanguage(in aLanguageOption varchar(30))
	begin
		insert into Language(languageOption) values (aLanguageOption);
    end;
/
    
create procedure insertPerformance(in aPerformanceTypeID int, in aLanguageID int, in aTitle varchar(100), in aDescription varchar(1000), in aHasLiveMusic boolean, in aImageUrl varchar(10000))
	begin
		insert into Performance(performanceTypeID, languageID, title, description, hasLiveMusic, imageUrl) values (aPerformanceTypeID, aLanguageID, aTitle, aDescription, aHasLiveMusic, aImageUrl);
	end;
/

create procedure insertPerformanceTiming(in aPerformanceID int, in aDateTimeOfPerformance datetime, in aDuration time)
	begin
		insert into PerformanceTiming(performanceID, dateTimeOfPerformance, duration) values (aPerformanceID, aDateTimeOfPerformance, aDuration);
	end;
/


create procedure insertTicket(in aSeatLocation varchar(100), in aPerformanceTimingID int, in aTicketPrice decimal(5, 2), in aPurchaseID int)
	begin
		insert into Ticket(seatLocation, performanceTimingID, ticketPrice, purchaseID) values (aSeatLocation, aPerformanceTimingID, aTicketPrice, aPurchaseID);
		update SeatTypePrice set seatAmount = seatAmount - 1 where seatType = aSeatLocation and performanceTimingID = aPerformanceTimingID;
	end;
/


create procedure insertSeatTypePrice
				(in aPerformanceTimingID int, in aSeatType varchar(100), in aSeatAmount int, in aPrice decimal(5, 2))
	begin 
		insert into SeatTypePrice(performanceTimingID, seatType, seatAmount, seatPrice) values (aPerformanceTimingID, aSeatType, aSeatAmount, aPrice);
	end;
/

create procedure searchForPerformances(in searchWord varchar(100), in aFromDate date, in aToDate date)
	begin
		if aFromDate is null and aToDate is null then
			select title, description, dateTimeOfPerformance, duration, seatType, seatPrice, PerformanceTiming.performanceTimingID, seatAmount from Performance 
            join PerformanceTiming on PerformanceTiming.performanceID = Performance.performanceID
            join SeatTypePrice on SeatTypePrice.performanceTimingID = PerformanceTiming.performanceTimingID
                where description like concat("%", searchWord, "%") or title like concat("%", searchWord, "%");
		elseif aToDate is null then
			select title, description, dateTimeOfPerformance, duration, seatType, seatPrice, PerformanceTiming.performanceTimingID, seatAmount from Performance 
            join PerformanceTiming on PerformanceTiming.performanceID = Performance.performanceID
            join SeatTypePrice on SeatTypePrice.performanceTimingID = PerformanceTiming.performanceTimingID
				where (description like concat("%", searchWord, "%") or title like concat("%", searchWord, "%"))
					and date(dateTimeOfPerformance) = aFromDate order by dateTimeOfPerformance asc;
		else
			select title, description, dateTimeOfPerformance, duration, seatType, seatPrice, PerformanceTiming.performanceTimingID, seatAmount from Performance 
            join PerformanceTiming on PerformanceTiming.performanceID = Performance.performanceID
            join SeatTypePrice on SeatTypePrice.performanceTimingID = PerformanceTiming.performanceTimingID
				where (description like concat("%", searchWord, "%") or title like concat("%", searchWord, "%"))
					and date(dateTimeOfPerformance) between aFromDate and aToDate order by dateTimeOfPerformance asc;
        end if;
    end;
/

create procedure getPerformanceTitle (in aPerformanceTimingID int)
		begin
			select title from Performance join PerformanceTiming on Performance.performanceID = PerformanceTiming.performanceID 
				where performanceTimingID = aPerformanceTimingID distinct;
        end;
/

/* create procedure buyTickets(in aSeatLocation varchar(6), in aUserID int, in aPerformanceTimingID int, in aTicketPrice int, in aMaxNumberOfSeats int, in quantity int)
    begin
        declare ticketsSold, seatsRemaining int;
        declare errorMsg varchar(100);
        select seatAmount into seatsRemaining from SeatTypePrice where seatType = aSeatLocation;
        set seatsRemainingAfterPurchase = seatsRemaining - quantity;
        -- raise an exception if customer tries to but more tickets than are available.
        -- dont sell any at all if they want to buy more than is available.
        if ticketsRemaining >= quantity then
            call insertPurchase();
        else
            signal sqlstate "45000" set message_text = concat(ticketsRemaining, " tickets remaining. Unable to complete purchase.");
            addToTickets: loop
                if quantity = 0 then
                    leave addToTickets;
                end if;
                call insertTicket(aSeatLocation, aUserID, aPerformanceTimingID, aTicketPrice);
                set quantity = quantity - 1;
            end loop addToTickets;
        end if;
    end;
    
    */
/
delimiter ;

Call insertUser('nathandrake@gmail.com', 'Fortune$$001', '1985-08-23', '123 Grove Lane');
Call insertUser('asandler@hotmail.com', 'W@terB0y473', '1965-02-04', '78 Stone Road');
Call insertUser('kevhart@yahoo.com', 'ImNotFunny:(', '1977-04-13', '11 Crocket Road');
Call insertUser('johnnyb@gmail.com', 'Passwor123', '2003-12-24', '8 Albion Road');
Call insertUser('Markz@hotmail.com', 'meT@verSe1823', '2009-03-27', '92 Hopework Drive');

Call insertPerformanceType('musical');
Call insertPerformanceType('opera');
Call insertPerformanceType('concert');
Call insertPerformanceType('theatre');

Call insertLanguage('English');
Call insertLanguage('Multiple languages');
Call insertLanguage('No language');

Call insertPerformance(1, 1,'The Lion King','The live action retelling of the classic disney moive',false,'https://lumiere-a.akamaihd.net/v1/images/image_fc5cb742.jpeg?region=0,0,540,810');
Call insertPerformance(1, 1, 'Elvis', 'Whilst on a mission to transform the mainstream rock and roll culture of the USA, singer Elvis Presley uses his fame to highlight racism within the country.', false,'https://m.media-amazon.com/images/M/MV5BYzMzNTJjYmMtZTkxNS00MjI4LWI3YmQtOTQ4MDZjZDJlZjQyXkEyXkFqcGdeQXVyNjc0NzQzNTM@._V1_.jpg');
Call insertPerformance(1, 1, 'The Wizard of Oz', 'The Wizard of Oz is a 2011 musical based on the 1939 film of the same name in turn based on L Frank Baum’s novel The Wonderful Wizard of Oz, with a book adapted by Andrew Lloyd Webber and Jeremy Sams.', false,'https://flxt.tmsimg.com/assets/p5095_p_v12_an.jpg');
Call insertPerformance(1, 1, 'Oliver!', 'Oliver! is a coming-of-age stage musical, with book, music and lyrics by Lionel Bart. The musical is based upon the 1838 novel Oliver Twist by Charles Dickens. It premiered at the Wimbledon Theatre, southwest London in 1960 before opening in the West End, where it enjoyed a record-breaking long run.', false,'https://m.media-amazon.com/images/M/MV5BNWQwNTE4NWQtZDg0MC00ZDhkLWIzMzQtNDU1MDIxZTNmM2M3XkEyXkFqcGdeQXVyNjE5MjUyOTM@._V1_.jpg');
Call insertPerformance(1, 1, 'Mamma Mia', 'Mamma Mia! is a jukebox musical written by British playwright Catherine Johnson, based on songs recorded by Swedish group ABBA and composed by Benny Andersson and Björn Ulvaeus, members of the band. The title of the musical is taken from the group''s 1975 chart-topper - Mamma Mia.', false,'https://www.goh.co.uk/wp-content/uploads/2019/09/Mamma-Mia-Square.jpg');

Call insertPerformance(2, 1, 'The Beggar''s Opera', 'The Beggar''s Opera is a ballad opera in three acts written in 1728 by John Gay with music arranged by Johann Christoph Pepusch. It is one of the watershed plays in Augustan drama and is the only example of the once thriving genre of satirical ballad opera to remain popular today.', true,'https://stagea.blob.core.windows.net/images/show/2479/the-beggars-opera-v4bozhfl.ogf.jpg');
Call insertPerformance(2, 2, 'The Cunning Little Vixen', 'The Cunning Little Vixen is a Czech-language opera by Leoš Janáček, composed in 1921 to 1923. Its libretto was adapted by the composer from a 1920 serialized novella, Liška Bystrouška, by Rudolf Těsnohlídek. The Czech title, Příhody lišky Bystroušky, means literally Tales of Vixen Sharp.', false,'https://calendar.artsboston.org/wp-content/uploads/sites/calendar.artsboston.org/images/2019/04/Vixen-e1555612621238-450x254.jpg');
Call insertPerformance(2, 1, 'Raymond and Agnes', 'Raymond and Agnes is an opera in 3 acts by the composer Edward Loder to an English libretto by Edward Fitzball. It is very loosely based on elements from Matthew Lewis''s classic Gothic novel, The Monk and also includes elements of Lewis''s The Castle Spectre.', true,'https://retrospectopera.org.uk/wp-content/uploads/2018/08/raymond-and-agnes-front-cover.jpg');
Call insertPerformance(2, 2, 'La bohème', 'La bohème is an opera in four acts, composed by Giacomo Puccini between 1893 and 1895 to an Italian libretto by Luigi Illica and Giuseppe Giacosa, based on Scènes de la vie de bohème by Henri Murger. The story is set in Paris around 1830 and shows the Bohemian lifestyle of a poor seamstress and her artist friends.', false,'https://c8.alamy.com/comp/C5WMH8/la-boheme-poster-an-early-production-of-puccinis-opera-C5WMH8.jpg'); 
Call insertPerformance(2, 2, 'L''Orfeo', 'L''Orfeo, sometimes called La favola d''Orfeo, is a late Renaissance/early Baroque favola in musica, or opera, by Claudio Monteverdi, with a libretto by Alessandro Striggio.', false,'http://archive.simonkeenlyside.info/wp-content/uploads/2010/02/Orfeo_DVD.jpg');

Call insertPerformance(3, 1, 'Coldplay', 'Coldplay are a British rock band formed in London in 1996. They consist of vocalist and pianist Chris Martin, guitarist Jonny Buckland, bassist Guy Berryman, drummer Will Champion and creative director Phil Harvey.', true, 'https://www.artelino.com/auctionimages/items/15480g1.jpg');
Call insertPerformance(3, 1, 'Arctic Monkeys', 'Arctic Monkeys are an English rock band formed in Sheffield in 2002. The group consists of Alex Turner, Jamie Cook, Nick O''Malley, and Matt Helders.', true, 'https://www.defining.co/wp-content/uploads/2022/09/ScreenShot2020-12-16at10.47.21AM_ad3a1a7e-bc1a-40ef-bb3b-1d68efcaf6d1.png);
Call insertPerformance(3, 2, 'Stromae', 'Paul Van Haver, better known by his stage name Stromae, is a Belgian singer, rapper, songwriter and producer. He is mostly known for his works in the genre of the hip hop and electronic music.', true, 'https://images-wixmp-ed30a86b8c4ca887773594c2.wixmp.com/f/6cf1ec7f-3236-4b9f-bc84-bc2c6e13392d/d7gwyb3-468a7eb7-7a0e-4cf8-b250-89f916d652ea.png?token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1cm46YXBwOjdlMGQxODg5ODIyNjQzNzNhNWYwZDQxNWVhMGQyNmUwIiwiaXNzIjoidXJuOmFwcDo3ZTBkMTg4OTgyMjY0MzczYTVmMGQ0MTVlYTBkMjZlMCIsIm9iaiI6W1t7InBhdGgiOiJcL2ZcLzZjZjFlYzdmLTMyMzYtNGI5Zi1iYzg0LWJjMmM2ZTEzMzkyZFwvZDdnd3liMy00NjhhN2ViNy03YTBlLTRjZjgtYjI1MC04OWY5MTZkNjUyZWEucG5nIn1dXSwiYXVkIjpbInVybjpzZXJ2aWNlOmZpbGUuZG93bmxvYWQiXX0.6-SUMu7DJKS0xzS4ervH0IzPZAavNuV7PvpZy_w9Xeg');
Call insertPerformance(3, 2, 'Bad Bunny', 'Bad Bunny, is a Puerto Rican rapper and singer. His music is defined as Latin trap and reggaeton. He rose to popularity in 2016 with his song "Diles".', true, 'https://toppng.com/uploads/preview/bad-bunny-11563057304ffa9k87zf6.png);
Call insertPerformance(3, 1, 'Stormzy', 'Stormzy, is a British rapper, singer and songwriter. In 2014, he gained attention on the UK underground music scene through his Wicked Skengman series of freestyles over classic grime beats.', true, 'https://www.defining.co/wp-content/uploads/2022/09/Stormzy_UKStreets_Poster.png');

Call insertPerformance(4, 1, 'Romeo and Juliet', 'Romeo and Juliet is a tragedy written by William Shakespeare early in his career about two young Italian star-crossed lovers whose deaths ultimately reconcile their feuding families.', true, 'https://kbimages1-a.akamaihd.net/ca07820a-192c-4ec8-a3a6-684a3a7ee2e3/353/569/90/False/romeo-and-juliet-320.jpg');
Call insertPerformance(4, 2, 'In the Solitude of Cotton Fields', 'In the Solitude of Cotton Fields is a two-character play by the French dramatist and writer Bernard-Marie Koltès in 1985.', true, 'https://m.media-amazon.com/images/I/41jUXOvy2SL.jpg');
Call insertPerformance(4, 1, 'The Women', 'The Women is a 1936 American play, a comedy of manners by Clare Boothe Luce. The cast includes women only.', false, 'https://i.gr-assets.com/images/S/compressed.photo.goodreads.com/books/1394489938l/17230502.jpg'); 
Call insertPerformance(4, 1, 'Midsummer Night''s Dream', 'A Midsummer Night''s Dream is a comedy written by William Shakespeare c. 1595 or 1596. The play is set in Athens, and consists of several subplots that revolve around the marriage of Theseus and Hippolyta. One subplot involves a conflict among four Athenian lovers.', false, 'https://m.media-amazon.com/images/I/81ebqGS8xCL._RI_.jpg');
Call insertPerformance(4, 2, 'Matsukaze', 'Matsukaze is a play of the third category, the woman''s mode, by Kan''ami, revised by Zeami Motokiyo. One of the most highly regarded of Noh plays, it is mentioned more than any other in Zeami''s own writings, and is depicted numerous times in the visual arts.',  false, 'https://www.artelino.com/auctionimages/items/15480g1.jpg');

Call insertPerformanceTiming(16, '2022-11-11 13:00', '02:00');
Call insertPerformanceTiming(16, '2022-11-11 19:00', '02:00');
Call insertPerformanceTiming(2, '2022-11-16 12:45', '01:40');
Call insertPerformanceTiming(15, '2022-11-16 18:00', '02:15');
Call insertPerformanceTiming(20, '2022-11-18 20:00', '01:00');
Call insertPerformanceTiming(13, '2022-11-11 18:00', '02:05');
Call insertPerformanceTiming(13, '2022-11-11 11:00', '02:05');

Call insertPerformanceTiming(6, '2022-11-14 16:30', '02:25');
Call insertPerformanceTiming(7, '2022-11-25 11:30', '02:00');
Call insertPerformanceTiming(7, '2022-11-25 17:30', '02:00');
Call insertPerformanceTiming(12, '2022-11-26 16:30', '02:30');
Call insertPerformanceTiming(9, '2022-11-27 11:00', '02:10');
Call insertPerformanceTiming(10, '2022-11-30 14:30', '01:40');

Call insertPerformanceTiming(19, '2022-12-06 18:30', '03:20');
Call insertPerformanceTiming(19, '2022-12-06 12:30', '03:20');
Call insertPerformanceTiming(8, '2022-12-04 13:00', '02:00');
Call insertPerformanceTiming(5, '2022-12-08 11:00', '01:30');
Call insertPerformanceTiming(5, '2022-12-08 16:00', '01:30');
Call insertPerformanceTiming(14, '2022-12-12 18:00', '02:30');
Call insertPerformanceTiming(3, '2022-12-12 10:00', '01:50');

Call insertPerformanceTiming(1, '2022-12-15 19:00', '01:40');
Call insertPerformanceTiming(1, '2022-12-15 12:00', '01:40');
Call insertPerformanceTiming(17, '2022-12-18 13:00', '02:20');
Call insertPerformanceTiming(18, '2022-12-20 18:00', '01:30');
Call insertPerformanceTiming(11, '2022-12-21 10:00', '01:20');
Call insertPerformanceTiming(11, '2022-12-21 19:00', '01:20');
Call insertPerformanceTiming(4, '2022-12-20 11:30', '02:00');

Call insertSeatTypePrice(1, 'stalls', 120, '50.00');
Call insertSeatTypePrice(1, 'circle', 80, '75.00');

Call insertSeatTypePrice(2, 'stalls', 120, '75.00');
Call insertSeatTypePrice(2, 'circle', 80, '100.00');

Call insertSeatTypePrice(3, 'stalls', 120, '50.00');
Call insertSeatTypePrice(3, 'circle', 80, '60.00');

Call insertSeatTypePrice(4, 'stalls', 120, '50.00');
Call insertSeatTypePrice(4, 'circle', 80, '75.00');

Call insertSeatTypePrice(5, 'stalls', 120, '50.00');
Call insertSeatTypePrice(5, 'circle', 80, '75.00');

Call insertSeatTypePrice(6, 'stalls', 120, '50.00');
Call insertSeatTypePrice(6, 'circle', 80, '75.00');

Call insertSeatTypePrice(7, 'stalls', 120, '50.00');
Call insertSeatTypePrice(7, 'circle', 80, '75.00');

Call insertSeatTypePrice(8, 'stalls', 120, '50.00');
Call insertSeatTypePrice(8, 'circle', 80, '75.00');

Call insertSeatTypePrice(9, 'stalls', 120, '25.00');
Call insertSeatTypePrice(9, 'circle', 80, '45.00');

Call insertSeatTypePrice(10, 'stalls', 120, '50.00');
Call insertSeatTypePrice(10, 'circle', 80, '75.00');

Call insertSeatTypePrice(11, 'stalls', 120, '50.00');
Call insertSeatTypePrice(11, 'circle', 80, '75.00');

Call insertSeatTypePrice(12, 'stalls', 120, '35.00');
Call insertSeatTypePrice(12, 'circle', 80, '50.00');

Call insertSeatTypePrice(13, 'stalls', 120, '50.00');
Call insertSeatTypePrice(13, 'circle', 80, '75.00');

Call insertSeatTypePrice(14, 'stalls', 120, '50.00');
Call insertSeatTypePrice(14, 'circle', 80, '75.00');

Call insertSeatTypePrice(15, 'stalls', 120, '50.00');
Call insertSeatTypePrice(15, 'circle', 80, '60.00');

Call insertSeatTypePrice(16, 'stalls', 120, '35.00');
Call insertSeatTypePrice(16, 'circle', 80, '50.00');

Call insertSeatTypePrice(17, 'stalls', 120, '30.00');
Call insertSeatTypePrice(17, 'circle', 80, '55.00');

Call insertSeatTypePrice(18, 'stalls', 120, '50.00');
Call insertSeatTypePrice(18, 'circle', 80, '75.00');

Call insertSeatTypePrice(19, 'stalls', 120, '50.00');
Call insertSeatTypePrice(19, 'circle', 80, '75.00');

Call insertSeatTypePrice(20, 'stalls', 120, '50.00');
Call insertSeatTypePrice(20, 'circle', 80, '75.00');

Call insertSeatTypePrice(21, 'stalls', 120, '35.00');
Call insertSeatTypePrice(21, 'circle', 80, '65.00');

Call insertSeatTypePrice(22, 'stalls', 120, '50.00');
Call insertSeatTypePrice(22, 'circle', 80, '75.00');

Call insertSeatTypePrice(23, 'stalls', 120, '50.00');
Call insertSeatTypePrice(23, 'circle', 80, '75.00');

Call insertSeatTypePrice(24, 'stalls', 120, '50.00');
Call insertSeatTypePrice(24, 'circle', 80, '75.00');

Call insertSeatTypePrice(25, 'stalls', 120, '40.00');
Call insertSeatTypePrice(25, 'circle', 80, '55.00');

Call insertSeatTypePrice(26, 'stalls', 120, '50.00');
Call insertSeatTypePrice(26, 'circle', 80, '75.00');

Call insertSeatTypePrice(27, 'stalls', 120, '30.00');
Call insertSeatTypePrice(27, 'circle', 80, '55.00');
