ALTER TABLE Users 
ADDWithDefault "Role" VARCHAR(50) DEFAULT 'Technicien';

-- Update existing users
UPDATE Users SET Role = 'Technicien' WHERE Role IS NULL OR Role = 'Technician';
UPDATE Users SET Role = 'Admin' WHERE Role = 'Administrator';
