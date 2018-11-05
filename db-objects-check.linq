<Query Kind="Statements">
  <NuGetReference>Newtonsoft.Json</NuGetReference>
  <Namespace>Newtonsoft.Json</Namespace>
  <Namespace>System.Net</Namespace>
</Query>

var dbDir = @"";

var rootUri = new Uri(dbDir);
var objects = File.ReadAllLines(Path.Combine(dbDir, "database-objects"));
var files = Directory
	.GetFiles(Path.Combine(dbDir, "schemas"), "*", SearchOption.AllDirectories)
	.Select(file => rootUri.MakeRelativeUri(new Uri(file)).ToString());

files
	.Where(file => !objects.Contains(file))
	.Dump();
objects
	.Where(obj => !files.Contains(obj))
	.Dump();