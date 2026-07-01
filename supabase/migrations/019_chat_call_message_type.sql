-- Call history entries in chat (missed, ended with duration, etc.)

ALTER TYPE message_type ADD VALUE IF NOT EXISTS 'call';
