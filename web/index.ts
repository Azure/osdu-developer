import { serve, file } from "bun";

const port = 8080;

const html = `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>OSDU Developer</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="icon" type="image/png" href="images/browser.png">
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
        .logo {
            width: auto;
            height: 33vh; /* Set height to 1/3 of viewport */
            margin-bottom: 20px;
        }
        /* Optionally adjust the container */
        .logo-container {
            height: 33vh; /* Logo container height 1/3 of viewport */
            display: flex;
            justify-content: center;
            align-items: center;
        }
    </style>
</head>
<body>
    <nav class="navbar navbar-expand-lg navbar-dark">
        <div class="container">
            <span class="navbar-brand mb-0 h1">OSDU Developer</span>
        </div>
    </nav>
    <div class="container mt-5 logo-container">
        <div class="d-flex justify-content-center">
            <img src="images/logo_white_bg.png" alt="OSDU Developer Logo" class="logo">
        </div>
    </div>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
`;

serve({
    port: port,
    async fetch(req) {
        const url = new URL(req.url);
        if (url.pathname === "/") {
            return new Response(html, {
                headers: { "Content-Type": "text/html" },
            });
        } else if (url.pathname === "/images/logo_white_bg.png") {
            const imageFile = file("images/logo_white_bg.png");
            return new Response(imageFile, {
                headers: { "Content-Type": "image/png" },
            });
        } else if (url.pathname === "/images/browser.png") {
            const faviconFile = file("images/browser.png");
            return new Response(faviconFile, {
                headers: { "Content-Type": "image/png" },
            });
        } else {
            return new Response("Not Found", { status: 404 });
        }
    },
});

console.log(`Server running at http://localhost:${port}`);
