# src/app.nim
import jazzy_desktop

# 1. Simple RPC: Types are strictly validated and handled by the macro
proc sayHello(name: string, age: int): string {.expose.} =
  return "Hello " & name & ", you are " & $age & " years old!"

# 2. Start the application
# We provide a basic HTML UI to test the macro output.
let htmlContent = """
  <!DOCTYPE html>
  <html>
  <head>
    <style>
      body { font-family: sans-serif; padding: 20px; background-color: #1e1e1e; color: #fff; }
      button { padding: 10px 15px; background-color: #646cff; color: white; border: none; border-radius: 5px; cursor: pointer; }
      button:hover { background-color: #535bf2; }
      #result { margin-top: 20px; padding: 15px; background-color: #2a2a2a; border-radius: 5px; border-left: 4px solid #646cff; }
    </style>
  </head>
  <body>
    <h1>Jazzy Desktop: Macro Testi</h1>
    <p>Aşağıdaki butona tıkladığında JavaScript, Nim arkaucuna istek atacak.</p>
    
    <button onclick="testMacro()">sayHello() Makrosunu Çağır</button>
    
    <div id="result">Bekleniyor...</div>

    <script>
      async function testMacro() {
        const resultDiv = document.getElementById("result");
        resultDiv.innerText = "Yükleniyor...";
        
        try {
          // Nim'deki `sayHello(name: string, age: int)` metoduna erişiyoruz
          const response = await window.sayHello("Caner", 25);
          resultDiv.innerText = "Nim'den Gelen Cevap: " + response.message;
        } catch (error) {
          resultDiv.innerText = "Hata: " + error;
        }
      }
    </script>
  </body>
  </html>
"""

startDesktopApp(
  title = "My Awesome App",
  width = 1024,
  height = 768,
  htmlContent = htmlContent
)
