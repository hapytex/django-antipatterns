sep=$(echo -e ". \n")

function make_toc() {
  fl=$(ls $1/*.md)
  head -q -n 1 $fl | cut -c 2- | paste -d ':' - <(echo "$fl") | sed -E 's/^.(.*)[:](.*)[.]md/ [\1](\2.html)/g' | paste -d '.' <(seq $(wc -l <<<"$fl")) -
}

echo -e "% Django (anti)patterns\n"

echo -e "## Antipatterns\n"

make_toc antipatterns

echo -e "\n\n## Patterns\n"

make_toc patterns

cat << EOM

<script data-name="BMC-Widget" src="https://cdnjs.buymeacoffee.com/1.0.0/widget.prod.min.js" data-id="hapytex" data-description="Support me on Buy me a coffee!" data-message="Thank you for visiting. You can now buy me a coffee!" data-color="#FFDD00" data-position="Right" data-x_margin="18" data-y_margin="18"></script>
EOM
