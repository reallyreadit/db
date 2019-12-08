<Query Kind="Program">
  <NuGetReference>Npgsql</NuGetReference>
  <Namespace>Npgsql</Namespace>
  <Namespace>System.Net</Namespace>
</Query>

void Main() {
	var conn = new NpgsqlConnection("");
	conn.Open();
	
	DecodeText(conn, "core.comment", "text");
	DecodeText(conn, "core.comment_revision", "original_text_content");
	DecodeText(conn, "core.comment_addendum", "text_content");
}

void DecodeText(NpgsqlConnection conn, string tableName, string columnName) {
	var reader = new NpgsqlCommand($"SELECT id, {columnName} FROM {tableName}", conn).ExecuteReader();
	var rows = new Dictionary<long, string>();
	while (reader.Read()) {
		rows.Add(reader.GetInt64("id"), reader.GetString(columnName));
	}
	reader.Close();
	foreach (var row in rows) {
		var updateCommand = new NpgsqlCommand($"UPDATE {tableName} SET {columnName} = @text WHERE id = @id", conn);
		updateCommand.Parameters.AddWithValue("text", WebUtility.HtmlDecode(row.Value));
		updateCommand.Parameters.AddWithValue("id", row.Key);
		updateCommand.ExecuteNonQuery();
	}
}