#!/bin/bash

echo "Starting entrypoint script"

[ -z "$REPOSITORY" ] && REPOSITORY="none"
[ -z "$BRANCH" ] && BRANCH="none"

echo "Repository: " $REPOSITORY
echo "Branch: " $BRANCH

cd /home/user/stable-diffusion-webui/extensions
git clone "$REPOSITORY" -b "$BRANCH"

MODEL_DIR="/home/user/models/"
SAVE_IMAGES_FOLDER="/home/user/horde/"

cd /home/user/stable-diffusion-webui/extensions/sd-webui-stable-horde-worker

ls $MODEL_DIR

# For Horde
# Initialize an empty JSON object for the configuration
config_json="{}"

# Function to add a key-value pair to the config JSON
add_to_config() {
  key="$1"
  value="$2"
  data_type="$3"
  
  if [ -n "$value" ] && [ "$value" != "none" ] && [ "$value" != "" ]; then
    case "$data_type" in
      "string")
        config_json=$(jq --arg key "$key" --arg value "$value" '. + { ($key): $value }' <<< "$config_json")
        ;;
      "int")
        # Convert the string value to an integer
        value_int=$((value))
        config_json=$(jq --arg key "$key" --argjson value "$value_int" '. + { ($key): $value }' <<< "$config_json")
        ;;
      "boolean")
        # Convert the string value to a boolean
        value_bool=$( [ "$value" == "true" ] && echo "true" || echo "false" )
        config_json=$(jq --arg key "$key" --argjson value "$value_bool" '. + { ($key): $value }' <<< "$config_json")
        ;;
      *)
        echo "Invalid data type for $key: $data_type"
        exit 1
        ;;
    esac
  fi
}

# Initialize environment variables with default values only if they are not set
[ -z "$ENABLED" ] && ENABLED="none"
[ -z "$ALLOW_IMG2IMG" ] && ALLOW_IMG2IMG="none"
[ -z "$ALLOW_PAINTING" ] && ALLOW_PAINTING="none"
[ -z "$ALLOW_UNSAFE_IPADDR" ] && ALLOW_UNSAFE_IPADDR="none"
[ -z "$ALLOW_POST_PROCESSING" ] && ALLOW_POST_PROCESSING="none"
[ -z "$RESTORE_SETTINGS" ] && RESTORE_SETTINGS="none"
[ -z "$SHOW_IMAGE_PREVIEW" ] && SHOW_IMAGE_PREVIEW="none"
[ -z "$SAVE_IMAGES" ] && SAVE_IMAGES="none"
[ -z "$SAVE_IMAGES_FOLDER" ] && SAVE_IMAGES_FOLDER="none"
[ -z "$ENDPOINT" ] && ENDPOINT="none"
[ -z "$APIKEY" ] && APIKEY="none"
[ -z "$NAME" ] && NAME="none"
[ -z "$INTERVAL" ] && INTERVAL="none"
[ -z "$MAX_PIXELS" ] && MAX_PIXELS="none"
[ -z "$NSFW" ] && NSFW="none"
[ -z "$HR_UPSCALER" ] && HR_UPSCALER="none"
[ -z "$HIRES_FIRSTPHASE_RESOLUTION" ] && HIRES_FIRSTPHASE_RESOLUTION="none"


# Specify the type for each environment variable and add to the config JSON
# Format: add_to_config "KEY" "VALUE" "TYPE"
add_to_config "enabled" $ENABLED "boolean"
add_to_config "allow_img2img" $ALLOW_IMG2IMG "boolean"
add_to_config "allow_painting" $ALLOW_PAINTING "boolean"
add_to_config "allow_unsafe_ipaddr" $ALLOW_UNSAFE_IPADDR "boolean"
add_to_config "allow_post_processing" $ALLOW_POST_PROCESSING "boolean"
add_to_config "restore_settings" $RESTORE_SETTINGS "boolean"
add_to_config "show_image_preview" $SHOW_IMAGE_PREVIEW "boolean"
add_to_config "save_images" $SAVE_IMAGES "boolean"
add_to_config "save_images_folder" $SAVE_IMAGES_FOLDER "string"
add_to_config "endpoint" $ENDPOINT "string"
add_to_config "apikey" $APIKEY "string"
add_to_config "name" $NAME "string"
add_to_config "interval" $INTERVAL "int"
add_to_config "max_pixels" $MAX_PIXELS "int"
add_to_config "nsfw" $NSFW "boolean"
add_to_config "hr_upscaler" $HR_UPSCALER "string"
add_to_config "hires_firstphase_resolution" $HIRES_FIRSTPHASE_RESOLUTION "int"

# Initialize an empty JSON object for current_models
models_json="{}"

# Loop through the files in $MODEL_DIR
for file in "$MODEL_DIR"/*; do
  if [ -f "$file" ]; then
    filename=$(basename "$file")
    name="${filename%%.*}" # Extract simplified name without extension

    # Add the JSON entry to the current_models object
    models_json=$(jq --arg name "$name" --arg filename "$filename" \
      '. += { ($name): $filename }' <<< "$models_json")
  fi
done

# Merge the generated current_models object with the existing JSON content
config_json=$(jq --argjson current_models "$models_json" '. + { "current_models": $current_models }' <<< "$config_json")

# Save the config to a file
echo "$config_json" > config.json

cat config.json

echo "Entrypoint script finished, starting webui.sh ..."

# Run webui.sh
cd /home/user/stable-diffusion-webui
./webui.sh --ckpt-dir "$MODEL_DIR" $COMMANDLINE_ARGS