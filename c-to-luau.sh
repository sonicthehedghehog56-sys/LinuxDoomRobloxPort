#!/bin/bash

# Convert C file to WASM then to Luau using Spider
# Usage: ./c-to-luau.sh path/to/file.c

if [ -z "$1" ]; then
    echo "❌ Error: No file path provided"
    echo "Usage: $0 path/to/file.c"
    exit 1
fi

C_FILE="$1"
FILENAME=$(basename "$C_FILE" .c)
WASM_FILE="${FILENAME}.wasm"
LUAU_FILE="${FILENAME}.luau"

# Check if file exists
if [ ! -f "$C_FILE" ]; then
    echo "❌ Error: File '$C_FILE' not found"
    exit 1
fi

echo "📦 Starting conversion process..."
echo "Input: $C_FILE"

# Step 1: Compile C to WASM using Emscripten
echo "🔄 Step 1: Converting C to WASM bytecode..."
emcc "$C_FILE" -O3 -o "$WASM_FILE"

if [ ! -f "$WASM_FILE" ]; then
    echo "❌ Error: WASM compilation failed"
    exit 1
fi

echo "✓ WASM file created: $WASM_FILE ($(du -h "$WASM_FILE" | cut -f1))"

# Step 2: Convert WASM to Luau using Spider
echo "🔄 Step 2: Converting WASM to Luau using Spider..."

# Create a temporary HTML file to run Spider conversion in browser
SPIDER_HTML="spider_converter.html"

cat > "$SPIDER_HTML" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>WASM to Luau Converter</title>
    <script src="https://unpkg.com/@hashintel/spider@latest"></script>
</head>
<body>
    <script>
        async function convertWasmToLuau(wasmPath) {
            try {
                const response = await fetch(wasmPath);
                const wasmBuffer = await response.arrayBuffer();
                const luauCode = await spider.wasmToLuau(wasmBuffer);
                
                // Copy to clipboard
                await navigator.clipboard.writeText(luauCode);
                console.log('✓ Conversion complete and copied to clipboard!');
                console.log(luauCode);
                
                return luauCode;
            } catch (error) {
                console.error('Error:', error);
            }
        }
        
        // Get WASM file path from URL parameter
        const params = new URLSearchParams(window.location.search);
        const wasmPath = params.get('wasm');
        if (wasmPath) convertWasmToLuau(wasmPath);
    </script>
</body>
</html>
EOF

echo "⚠️  Note: Spider conversion requires a browser environment"
echo "📂 Files created:"
echo "  - $WASM_FILE (WebAssembly bytecode)"
echo "  - $SPIDER_HTML (Open this in a browser to convert WASM → Luau)"
echo ""
echo "🌐 To complete the conversion:"
echo "  1. Open '$SPIDER_HTML' in your web browser"
echo "  2. The conversion will run automatically"
echo "  3. Result will be copied to your clipboard"
echo ""
echo "Or use this direct command in browser console:"
echo "  const wasm = await fetch('./$WASM_FILE').then(r => r.arrayBuffer());"
echo "  const luau = await spider.wasmToLuau(wasm);"
echo "  await navigator.clipboard.writeText(luau);"
echo "  console.log(luau);"
