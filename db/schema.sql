DROP DATABASE IF EXISTS protraining360;
CREATE DATABASE protraining360 CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE protraining360;

CREATE TABLE Organisation (
    pk_Organisation  INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    name             VARCHAR(100)  NOT NULL,
    legalName        VARCHAR(150)  NOT NULL,
    vatNumber        VARCHAR(20)   NULL,
    street           VARCHAR(100)  NULL,
    postalCode       VARCHAR(10)   NULL,
    city             VARCHAR(60)   NULL,
    email            VARCHAR(254)  NOT NULL,
    phone            VARCHAR(20)   NULL,
    PRIMARY KEY (pk_Organisation)
);

CREATE TABLE Club (
    pk_Club                 INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    name                    VARCHAR(100)  NOT NULL,
    description             TEXT          NULL,
    email                   VARCHAR(254)  NULL,
    phone                   VARCHAR(20)   NULL,
    createdAt               DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fk_Organisation_groups  INT UNSIGNED  NOT NULL,
    PRIMARY KEY (pk_Club),
    CONSTRAINT fkc_Club_groups_Organisation FOREIGN KEY (fk_Organisation_groups)
        REFERENCES Organisation (pk_Organisation) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE Sport (
    pk_Sport  SMALLINT UNSIGNED  NOT NULL AUTO_INCREMENT,
    name      VARCHAR(50)        NOT NULL,
    category  VARCHAR(40)        NULL,          -- team sport, water sport, racket sport, ...
    PRIMARY KEY (pk_Sport)
);

CREATE TABLE User (
    pk_User                      INT UNSIGNED        NOT NULL AUTO_INCREMENT,
    email                        VARCHAR(254)        NOT NULL,
    passwordHash                 VARCHAR(255)        NOT NULL,     -- bcrypt / argon2
    firstName                    VARCHAR(50)         NOT NULL,
    lastName                     VARCHAR(50)         NOT NULL,
    birthDate                    DATE                NULL,
    phone                        VARCHAR(20)         NULL,
    preferredLanguage            ENUM('EN','FR','DE') NOT NULL DEFAULT 'EN',
    isActive                     BOOLEAN             NOT NULL DEFAULT TRUE,
    createdAt                    DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fk_Organisation_administers  INT UNSIGNED        NULL,         -- set = organisation role
    PRIMARY KEY (pk_User),
    CONSTRAINT fkc_User_administers_Organisation FOREIGN KEY (fk_Organisation_administers)
        REFERENCES Organisation (pk_Organisation) ON DELETE SET NULL ON UPDATE CASCADE
);

-- Not in the CDM: technical table for revocable JWT refresh tokens
CREATE TABLE RefreshToken (
    pk_RefreshToken    BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT,
    tokenHash          CHAR(64)         NOT NULL,                 -- SHA-256, never the token itself
    issuedAt           DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expiresAt          DATETIME         NOT NULL,
    revokedAt          DATETIME         NULL,
    fk_User_belongsTo  INT UNSIGNED     NOT NULL,
    PRIMARY KEY (pk_RefreshToken),
    CONSTRAINT fkc_RefreshToken_belongsTo_User FOREIGN KEY (fk_User_belongsTo)
        REFERENCES User (pk_User) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Qualification (
    pk_Qualification  INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    title             VARCHAR(100)  NOT NULL,
    issuingBody       VARCHAR(100)  NOT NULL,
    level             VARCHAR(30)   NULL,
    validUntil        DATE          NULL,
    fk_User_obtains   INT UNSIGNED  NOT NULL,
    PRIMARY KEY (pk_Qualification),
    CONSTRAINT fkc_Qualification_obtains_User FOREIGN KEY (fk_User_obtains)
        REFERENCES User (pk_User) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Notification (
    pk_Notification   BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT,
    type              ENUM('SESSION_CANCELLED','SESSION_CHANGED','WAITLIST_PROMOTED','GENERAL') NOT NULL,
    title             VARCHAR(150)     NOT NULL,
    body              TEXT             NULL,
    isRead            BOOLEAN          NOT NULL DEFAULT FALSE,
    createdAt         DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fk_User_receives  INT UNSIGNED     NOT NULL,
    PRIMARY KEY (pk_Notification),
    CONSTRAINT fkc_Notification_receives_User FOREIGN KEY (fk_User_receives)
        REFERENCES User (pk_User) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Facility (
    pk_Facility               INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    name                      VARCHAR(100)  NOT NULL,
    street                    VARCHAR(100)  NULL,
    postalCode                VARCHAR(10)   NULL,
    city                      VARCHAR(60)   NULL,
    latitude                  DECIMAL(9,6)  NULL,
    longitude                 DECIMAL(9,6)  NULL,
    fk_Organisation_operates  INT UNSIGNED  NOT NULL,
    PRIMARY KEY (pk_Facility),
    CONSTRAINT fkc_Facility_operates_Organisation FOREIGN KEY (fk_Organisation_operates)
        REFERENCES Organisation (pk_Organisation) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE OpeningHour (
    pk_OpeningHour       INT UNSIGNED      NOT NULL AUTO_INCREMENT,
    weekday              TINYINT UNSIGNED  NOT NULL,              -- 1 = Monday ... 7 = Sunday
    opensAt              TIME              NOT NULL,
    closesAt             TIME              NOT NULL,
    fk_Facility_defines  INT UNSIGNED      NOT NULL,
    PRIMARY KEY (pk_OpeningHour),
    CONSTRAINT fkc_OpeningHour_defines_Facility FOREIGN KEY (fk_Facility_defines)
        REFERENCES Facility (pk_Facility) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Infrastructure (
    pk_Infrastructure     INT UNSIGNED       NOT NULL AUTO_INCREMENT,
    name                  VARCHAR(100)       NOT NULL,
    type                  VARCHAR(40)        NOT NULL,            -- field, hall, pool, court, ...
    capacity              SMALLINT UNSIGNED  NULL,                -- max people at once
    isActive              BOOLEAN            NOT NULL DEFAULT TRUE,
    fk_Facility_contains  INT UNSIGNED       NOT NULL,
    PRIMARY KEY (pk_Infrastructure),
    CONSTRAINT fkc_Infrastructure_contains_Facility FOREIGN KEY (fk_Facility_contains)
        REFERENCES Facility (pk_Facility) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE Equipment (
    pk_Equipment        INT UNSIGNED       NOT NULL AUTO_INCREMENT,
    name                VARCHAR(100)       NOT NULL,
    totalQuantity       SMALLINT UNSIGNED  NOT NULL,
    isActive            BOOLEAN            NOT NULL DEFAULT TRUE,
    fk_Facility_stores  INT UNSIGNED       NOT NULL,
    PRIMARY KEY (pk_Equipment),
    CONSTRAINT fkc_Equipment_stores_Facility FOREIGN KEY (fk_Facility_stores)
        REFERENCES Facility (pk_Facility) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE supports (
    pkfk_Infrastructure  INT UNSIGNED       NOT NULL,
    pkfk_Sport           SMALLINT UNSIGNED  NOT NULL,
    PRIMARY KEY (pkfk_Infrastructure, pkfk_Sport),
    CONSTRAINT fkc_supports_Infrastructure FOREIGN KEY (pkfk_Infrastructure)
        REFERENCES Infrastructure (pk_Infrastructure) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fkc_supports_Sport FOREIGN KEY (pkfk_Sport)
        REFERENCES Sport (pk_Sport) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE isUsedFor (
    pkfk_Equipment  INT UNSIGNED       NOT NULL,
    pkfk_Sport      SMALLINT UNSIGNED  NOT NULL,
    PRIMARY KEY (pkfk_Equipment, pkfk_Sport),
    CONSTRAINT fkc_isUsedFor_Equipment FOREIGN KEY (pkfk_Equipment)
        REFERENCES Equipment (pk_Equipment) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fkc_isUsedFor_Sport FOREIGN KEY (pkfk_Sport)
        REFERENCES Sport (pk_Sport) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- role is part of the key: one user can be TRAINER and PARTICIPANT in the same club
CREATE TABLE isMemberOf (
    pkfk_User  INT UNSIGNED                     NOT NULL,
    pkfk_Club  INT UNSIGNED                     NOT NULL,
    pk_role    ENUM('TRAINER','PARTICIPANT')    NOT NULL,
    status     ENUM('ACTIVE','SUSPENDED')       NOT NULL DEFAULT 'ACTIVE',
    joinedAt   DATETIME                         NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (pkfk_User, pkfk_Club, pk_role),
    CONSTRAINT fkc_isMemberOf_User FOREIGN KEY (pkfk_User)
        REFERENCES User (pk_User) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fkc_isMemberOf_Club FOREIGN KEY (pkfk_Club)
        REFERENCES Club (pk_Club) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE TrainingSession (
    pk_TrainingSession              INT UNSIGNED       NOT NULL AUTO_INCREMENT,
    title                           VARCHAR(100)       NOT NULL,
    description                     TEXT               NULL,
    sessionDate                     DATE               NOT NULL,
    startTime                       TIME               NOT NULL,
    endTime                         TIME               NOT NULL,
    capacity                        SMALLINT UNSIGNED  NOT NULL,
    level                           ENUM('ALL','BEGINNER','INTERMEDIATE','ADVANCED') NOT NULL DEFAULT 'ALL',
    price                           DECIMAL(7,2)       NOT NULL DEFAULT 0.00,
    status                          ENUM('SCHEDULED','CANCELLED') NOT NULL DEFAULT 'SCHEDULED',
    createdAt                       DATETIME           NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updatedAt                       DATETIME           NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    fk_Club_organises               INT UNSIGNED       NOT NULL,
    fk_User_leads                   INT UNSIGNED       NOT NULL,
    fk_Sport_concerns               SMALLINT UNSIGNED  NOT NULL,
    fk_Infrastructure_takesPlaceAt  INT UNSIGNED       NOT NULL,
    PRIMARY KEY (pk_TrainingSession),
    CONSTRAINT fkc_TrainingSession_organises_Club FOREIGN KEY (fk_Club_organises)
        REFERENCES Club (pk_Club) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fkc_TrainingSession_leads_User FOREIGN KEY (fk_User_leads)
        REFERENCES User (pk_User) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fkc_TrainingSession_concerns_Sport FOREIGN KEY (fk_Sport_concerns)
        REFERENCES Sport (pk_Sport) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fkc_TrainingSession_takesPlaceAt_Infrastructure FOREIGN KEY (fk_Infrastructure_takesPlaceAt)
        REFERENCES Infrastructure (pk_Infrastructure) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE allocates (
    pkfk_TrainingSession  INT UNSIGNED       NOT NULL,
    pkfk_Equipment        INT UNSIGNED       NOT NULL,
    quantity              SMALLINT UNSIGNED  NOT NULL,
    PRIMARY KEY (pkfk_TrainingSession, pkfk_Equipment),
    CONSTRAINT fkc_allocates_TrainingSession FOREIGN KEY (pkfk_TrainingSession)
        REFERENCES TrainingSession (pk_TrainingSession) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fkc_allocates_Equipment FOREIGN KEY (pkfk_Equipment)
        REFERENCES Equipment (pk_Equipment) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE registersFor (
    pkfk_User             INT UNSIGNED       NOT NULL,
    pkfk_TrainingSession  INT UNSIGNED       NOT NULL,
    status                ENUM('ACTIVE','WAITLISTED','CANCELLED') NOT NULL DEFAULT 'ACTIVE',
    registeredAt          DATETIME           NOT NULL DEFAULT CURRENT_TIMESTAMP,
    cancelledAt           DATETIME           NULL,
    waitlistPosition      SMALLINT UNSIGNED  NULL,
    attended              BOOLEAN            NULL,          -- NULL until the trainer takes attendance
    paymentStatus         ENUM('NOT_REQUIRED','PENDING','PAID','REFUNDED') NOT NULL DEFAULT 'NOT_REQUIRED',
    PRIMARY KEY (pkfk_User, pkfk_TrainingSession),
    CONSTRAINT fkc_registersFor_User FOREIGN KEY (pkfk_User)
        REFERENCES User (pk_User) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fkc_registersFor_TrainingSession FOREIGN KEY (pkfk_TrainingSession)
        REFERENCES TrainingSession (pk_TrainingSession) ON DELETE CASCADE ON UPDATE CASCADE
);

