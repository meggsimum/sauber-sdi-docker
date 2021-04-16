\c sauber_data

CREATE TABLE image_mosaics.raster_metadata (
	idpk_image serial NOT NULL,
	image_path text NOT NULL,
	source_payload jsonb NOT NULL,
	workspace text NOT NULL,
	coverage_store text NOT NULL,
	image_mosaic text NOT NULL,
	is_published int2 NOT NULL DEFAULT 0,
	CONSTRAINT raster_metadata_chk CHECK (((is_published = ANY (ARRAY[0, 1])))),
	CONSTRAINT raster_metadata_pkey PRIMARY KEY (idpk_image),
	CONSTRAINT raster_metadata_uq_path UNIQUE (image_path)
);

ALTER TABLE image_mosaics.raster_metadata ADD COLUMN IF NOT EXISTS properties_path TEXT;
ALTER TABLE image_mosaics.raster_metadata OWNER TO sauber_manager;
GRANT SELECT ON TABLE image_mosaics.raster_metadata TO sauber_user;
GRANT INSERT ON TABLE image_mosaics.raster_metadata TO sauber_user;
GRANT UPDATE ON TABLE image_mosaics.raster_metadata TO sauber_user;
GRANT ALL ON TABLE image_mosaics.raster_metadata TO sauber_manager;
GRANT SELECT,INSERT,UPDATE ON TABLE image_mosaics.raster_metadata TO app;
GRANT SELECT,INSERT,UPDATE ON TABLE image_mosaics.raster_metadata TO sauber_user;
GRANT SELECT,UPDATE ON TABLE image_mosaics.raster_metadata TO anon;
