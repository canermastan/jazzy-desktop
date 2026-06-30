import webview
import std/[json, strutils]

# This is the callback function that will be executed when JavaScript calls `window.helloFromNim()`
proc helloCallback(seq: cstring, req: cstring, arg: pointer) {.cdecl.} =
  let w = cast[Webview](arg)
  
  # `req` is a JSON array string representing the arguments passed from JS, e.g. `["Caner"]`
  # We parse it to extract the arguments.
  let args = parseJson($req)
  let name = args[0].getStr()
  
  # Prepare the response as a JSON string
  let responseObj = %*{"message": "Merhaba " & name & ", Nim'den sevgiler!"}
  let responseStr = $responseObj
  
  # Return the result back to JavaScript (0 means success)
  w.returnResult(seq, 0, cstring(responseStr))

proc main() =
  let w = webview.create(1, nil)
  if w == nil:
    quit("Failed to create webview instance")

  w.setTitle("Jazzy Desktop RPC Test")
  w.setSize(800, 600, WebviewHint.None)
  
  # Bind our Nim function to the JavaScript environment under the name "helloFromNim"
  w.bindFn("helloFromNim", helloCallback, w)

  # A simple UI to test the communication
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
      <h1>Jazzy Desktop: RPC Testi</h1>
      <p>Aşağıdaki butona tıkladığında JavaScript, Nim arkaucuna (backend) istek atacak ve gelen cevabı ekrana yazdıracak.</p>
      
      <button onclick="testRPC()">Nim'i Çağır</button>
      
      <div id="result">Bekleniyor...</div>

      <script>
        async function testRPC() {
          const resultDiv = document.getElementById("result");
          resultDiv.innerText = "Yükleniyor...";
          
          try {
            // MAGIC HAPPENS HERE: Calling the Nim backend directly!
            const response = await window.helloFromNim("Caner");
            resultDiv.innerText = "Nim'den Gelen Cevap: " + response.message;
          } catch (error) {
            resultDiv.innerText = "Hata: " + error;
          }
        }
      </script>
    </body>
    </html>
  """

  w.setHtml(cstring(htmlContent))
  discard w.run()
  discard w.destroy()

main()
