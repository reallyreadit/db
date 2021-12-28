-- Create API endpoint for author/user account assignments.
CREATE FUNCTION
	authors.assign_user_account_to_author(
		author_id bigint,
		user_account_id bigint
	)
RETURNS
	SETOF authors.author
LANGUAGE
	plpgsql
AS $$
BEGIN
	-- Create the assignment.
	INSERT INTO
		core.author_user_account_assignment (
			author_id,
			user_account_id,
			date_assigned
		)
	VALUES (
		assign_user_account_to_author.author_id,
		assign_user_account_to_author.user_account_id,
		core.utc_now()
	);
	-- Return from view.
	RETURN QUERY
	SELECT
		*
	FROM
		authors.author
	WHERE
		author.id = assign_user_account_to_author.author_id;
END;
$$;

-- Add author payout report.
CREATE FUNCTION
	subscriptions.run_payout_report()
RETURNS
	TABLE (
		author_name text,
		total_earnings int,
		total_payouts int,
		total_donations int,
		current_balance int
	)
LANGUAGE
	sql
STABLE
AS $$
	WITH earnings AS (
		SELECT
			author_id,
			amount_earned
		FROM
			subscriptions.run_authors_earnings_report(
				min_amount_earned := 1000,
				max_amount_earned := 0
			)
	),
	payouts AS (
		SELECT
			assignment.author_id,
			sum(author_payout.amount)::int AS total_amount
		FROM
			core.payout_account
			JOIN
				core.author_payout ON
					payout_account.id = author_payout.payout_account_id
			JOIN
				core.author_user_account_assignment AS assignment ON
					payout_account.user_account_id = assignment.user_account_id
		GROUP BY
			assignment.author_id
	),
	donations AS (
		SELECT
			coalesce(donation_account.author_id, assignment.author_id) AS author_id,
			sum(donation_payout.amount)::int AS total_amount
		FROM
			core.donation_account
			JOIN
				core.donation_payout ON
					donation_account.id = donation_payout.donation_account_id
			LEFT JOIN
				core.author_user_account_assignment AS assignment ON
					donation_account.user_account_id = assignment.user_account_id
		GROUP BY
			donation_account.author_id,
			assignment.author_id
	)
	SELECT
		author.name,
		earnings.amount_earned AS total_earnings,
		coalesce(payouts.total_amount, 0) AS total_payouts,
		coalesce(donations.total_amount, 0) AS total_donations,
		(earnings.amount_earned - coalesce(payouts.total_amount, 0) - coalesce(donations.total_amount, 0)) AS current_balance
	FROM
		core.author
		JOIN
			earnings ON
				author.id = earnings.author_id
		LEFT JOIN
			payouts ON
				author.id = payouts.author_id
		LEFT JOIN
			donations ON
				author.id = donations.author_id
	WHERE
		payouts.author_id IS NOT NULL OR
		donations.author_id IS NOT NULL
	ORDER BY
		current_balance DESC;
$$;