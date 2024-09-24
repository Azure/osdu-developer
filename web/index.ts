import { serve } from "bun";

const port = 8000;

const html = `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>OSDU Developer</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        body {
            background-color: #ffffff;
        }
        .navbar {
            background-color: #01696e !important;
        }
        .navbar-brand {
            color: #ffffff !important;
        }
    </style>
</head>
<body>
    <nav class="navbar navbar-expand-lg navbar-dark">
        <div class="container">
            <span class="navbar-brand mb-0 h1">OSDU Developer</span>
        </div>
    </nav>
    <div class="container mt-5">
        <h1 class="text-center" style="color: #01696e;">Welcome to OSDU Developer</h1>
        <p class="text-center">This is a simple webpage served by Bun.</p>
    </div>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
`;

serve({
    port: port,
    fetch(req) {
        return new Response(html, {
            headers: { "Content-Type": "text/html" },
        });
    },
});

console.log(`Server running at http://localhost:${port}`);
