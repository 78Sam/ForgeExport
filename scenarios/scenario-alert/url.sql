-- Just paste these into the phpmyadmin page (wordpress db)

-- Change to scenario URL

UPDATE wp_options SET option_value = replace(option_value, 'http://localhost:8000', 'http://172.18.0.2') WHERE option_name = 'home' OR option_name = 'siteurl';
UPDATE wp_posts SET guid = replace(guid, 'http://localhost:8000','http://172.18.0.2');
UPDATE wp_posts SET post_content = replace(post_content, 'http://localhost:8000', 'http://172.18.0.2');
UPDATE wp_postmeta SET meta_value = replace(meta_value,'http://localhost:8000','http://172.18.0.2');

-- Change to debug URL

UPDATE wp_options SET option_value = replace(option_value, 'http://172.18.0.2', 'http://localhost:8000') WHERE option_name = 'home' OR option_name = 'siteurl';
UPDATE wp_posts SET guid = replace(guid, 'http://172.18.0.2','http://localhost:8000');
UPDATE wp_posts SET post_content = replace(post_content, 'http://172.18.0.2', 'http://localhost:8000');
UPDATE wp_postmeta SET meta_value = replace(meta_value,'http://172.18.0.2','http://localhost:8000');