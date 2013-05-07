require 'sinatra'
require './parser'

get '/' do
	@time = Time.now
  erb :index
end

__END__

@@ layout
<!DOCTYPE html>
<html lang="en-GB">
<head>
	<title>LordsWhip</title>
	<meta name="viewport" content="width=device-width, initial-scale=1.0">
		<link href="css/bootstrap.min.css" rel="stylesheet" media="screen">
		<link href="css/bootstrap-responsive.min.css" rel="stylesheet">
	</head>
	<body>
		<div class="container"><%= yield %></div>
  <script src="http://code.jquery.com/jquery.js"></script>
  <script src="js/bootstrap.min.js"></script>
</body>
</html>


@@ index
<div class="page-header">
  <h1>LordsWhip <small>Calendar</small></h1>
</div>

<p class="lead">lorem ipsum</p>
<p><%= @time %></p>
