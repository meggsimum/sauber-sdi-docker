\c sauber_data

CREATE TABLE IF NOT EXISTS public.test_updater (
	ts TIMESTAMP NULL
);

INSERT INTO test_updater 
VALUES (now());