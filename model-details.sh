#! /bin/bash

package_config=$(cat mlc-package-config.json)
app_config=$(cat dist/bundle/mlc-app-config.json)

for model_id in $(jq -r '.model_list[].model_id' <<< $package_config); do
    name=$(jq -r ".model_list[] | select(.model_id==\"$model_id\") | .name" <<< $package_config)
    bytes=$(jq -r ".model_list[] | select(.model_id==\"$model_id\") | .bytes" <<< $package_config)
    group=$(jq -r ".model_list[] | select(.model_id==\"$model_id\") | .group" <<< $package_config)

    jq_exp=".model_list[] |= if (.model_id==\"$model_id\") then .+ {\"name\":\"$name\",\"bytes\":$bytes, \"group\":\"$group\"} else . end"

    app_config=$(jq "$jq_exp" <<< $app_config)

done

echo $app_config | jq . > dist/bundle/mlc-app-config.json
