set -e
cd ~/ScoreLive

python3 - << 'PYEOF'
p = "app/build.gradle.kts"
s = open(p).read()

# Bozuk HOST blogunu tamamen kaldir (kacis karakterleri hatali eklenmisti)
import re
s = re.sub(
    r'\s*buildConfigField\(\s*"String",\s*"SPORTS_API_HOST",[^)]*\)\s*',
    '\n',
    s
)

# Dogru HOST blogunu BASE_URL blogunun oncesine ekle
anchor = '''        buildConfigField(
            "String",
            "SPORTS_API_BASE_URL",'''

host_block = '''        buildConfigField(
            "String",
            "SPORTS_API_HOST",
            "\\"${localProperties.getProperty("SPORTS_API_HOST", "")}\\""
        )
'''

if "SPORTS_API_HOST" not in s:
    s = s.replace(anchor, host_block + anchor, 1)

open(p, "w").write(s)
print("build.gradle.kts duzeltildi")
PYEOF

echo "--- 30-45 satirlar ---"
sed -n '30,45p' app/build.gradle.kts

git add .
git commit -m "Fix: correct escaping in SPORTS_API_HOST buildConfigField"
git push
echo "TAMAMLANDI"
