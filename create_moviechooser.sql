/*
* Authors: Rubén Cerdà-Bacete, Sofia Llàcer Caro
*/

DROP SCHEMA IF EXISTS movie_chooser CASCADE;

-- Make sure that you have created a role as in:
-- CREATE ROLE datadates WITH USER sofia, cerbaru [other users...];
CREATE SCHEMA movie_chooser AUTHORIZATION datadates;

GRANT ALL ON SCHEMA movie_chooser TO datadates;

SET search_path TO movie_chooser;

BEGIN WORK;

SET TRANSACTION READ WRITE;

SET datestyle = DMY;

CREATE TABLE DIRECTOR (
    director_id SMALLINT,
    name VARCHAR(100) NOT NULL,
    birth DATE DEFAULT NULL,
    death DATE DEFAULT NULL,
    gender VARCHAR(10),
    nationality VARCHAR(50) NOT NULL,
    CONSTRAINT PK_DIRECTOR PRIMARY KEY(director_id)
);

CREATE TABLE MOVIE (
    movie_id SMALLINT,
    title VARCHAR(255) NOT NULL,
    year SMALLINT NOT NULL,
    --director_id SMALLINT,
    rotten_tomatoes REAL CHECK (rotten_tomatoes BETWEEN 0 AND 10),
    google REAL CHECK (google BETWEEN 0 AND 10),
    imbd REAL CHECK (imbd BETWEEN 0 AND 10),
    film_affinity REAL CHECK (film_affinity BETWEEN 0 AND 10),
    rating REAL CHECK (rating BETWEEN 0 AND 10), --BETWEEN 0 AND 10, --(?)
    genre VARCHAR(100) DEFAULT 'Not classified',
    duration INTERVAL HOUR TO MINUTE,
    platform VARCHAR(255) DEFAULT 'Not found',
    link VARCHAR(7000),
    sofia_watched BOOLEAN,
    adrian_watched BOOLEAN,
    CONSTRAINT PK_MOVIE PRIMARY KEY(movie_id),
    CONSTRAINT FK_DIRECTOR_MOVIES FOREIGN KEY(director_id) REFERENCES DIRECTOR(director_id)
);

CREATE TABLE DIRECTED (
    movie_id SMALLINT,
    director_id SMALLINT,
    CONSTRAINT PK_DIRECTED PRIMARY KEY(movie_id, director_id),
    CONSTRAINT FK_DIRECTOR FOREIGN KEY(director_id) REFERENCES DIRECTOR(director_id),
    CONSTRAINT FK_MOVIE FOREIGN KEY(movie_id) REFERENCES MOVIE(movie_id)
);

-- Reassign ownership of all created tables to the group datadates.
-- Do on insertion of new tables and rebuilding of the database
REASSIGN OWNED BY cerbaru TO datadates;

COMMIT;

/* TRIGGER */
CREATE OR REPLACE FUNCTION average_rating()
RETURNS TRIGGER AS $$
DECLARE
	num_avg INT;
    value INT;
BEGIN
	IF(NOT (OLD.rotten_tomatoes = NEW.rotten_tomatoes AND
            OLD.google = NEW.google AND
            OLD.imdb = NEW.imdb AND
            OLD.film_affinity = NEW.film_affinity
            )
        ) THEN

        num_avg = 4;
        IF( NEW.rotten_tomatoes = NULL) THEN num_avg = num_avg - 1; END IF;
        IF( NEW.google = NULL) THEN num_avg = num_avg - 1; END IF;
        IF( NEW.imdb = NULL) THEN num_avg = num_avg - 1; END IF;
        IF( NEW. film_affinity = NULL) THEN num_avg = num_avg - 1; END IF;

        IF(num_avg > 0) THEN
            value = (NEW.rotten_tomatoes + NEW.google + NEW.imbd + NEW.film_affinity) / num_avg;
        ELSE
            value = NULL;
        END IF;

        UPDATE MOVIE SET rating = value WHERE movie_id = NEW.movie_id;

    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER trig_average_rating ON movie;

CREATE TRIGGER trig_average_rating
AFTER INSERT OR UPDATE OF rotten_tomatoes, google, imbd, film_affinity
ON MOVIE
FOR EACH ROW
EXECUTE FUNCTION average_rating();
