-- Add missing foreign key constraint.
ALTER TABLE
	core.subscription_period_author_distribution
ADD CONSTRAINT
	subscription_period_author_distribution_author_id_fkey
FOREIGN KEY (
	author_id
)
REFERENCES
	core.author (
		id
	);