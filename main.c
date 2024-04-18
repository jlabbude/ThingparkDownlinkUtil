#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "cJSON.h"

char *build_final_json(const char *eui_array[], int eui_count) {
    // Create a root JSON object
    cJSON *root = cJSON_CreateObject();
    // Create a JSON array to hold the EUIs
    cJSON *eui_json_array = cJSON_CreateArray();

    // Loop through each EUI and add it to the array
    for (int i = 0; i < eui_count; i++) {
        // Create a JSON string for each EUI and add it to the array
        cJSON *eui_item = cJSON_CreateString(eui_array[i]);
        cJSON_AddItemToArray(eui_json_array, eui_item);
    }

    // Add the array of EUIs to the root object under the key "EUI"
    cJSON_AddItemToObject(root, "EUI", eui_json_array);

    // Convert the root JSON object to a string
    char *json_str = cJSON_Print(root);
    // Delete the root JSON object to free memory
    cJSON_Delete(root);

    return json_str;
}

//recursively filters JSONs
void filterJSON(const cJSON *json, const char *key, const char **eui_array, int *eui_count) {
    if (json == NULL) return;

    if (json->type == cJSON_Object) {
        cJSON *item = cJSON_GetObjectItemCaseSensitive(json, key);
        if (item != NULL && cJSON_IsString(item) && strcmp(item->string, key) == 0) {
            // Add the value of the string to the EUI array
            eui_array[(*eui_count)++] = strdup(item->valuestring);
        }
        // Recursively call filterJSON for each child element
        cJSON *child;
        cJSON_ArrayForEach(child, json) {
            filterJSON(child, key, eui_array, eui_count);
        }
    }

    else if (json->type == cJSON_Array) {
        cJSON *item;
        cJSON_ArrayForEach(item, json) {
            filterJSON(item, key, eui_array, eui_count);
        }
    }
}

int main() {
    FILE *fp = fopen("JSON_output/verbose.json", "r");
    if (fp == NULL) {
        printf("Error opening JSON file\n");
        return 1;
    }

    fseek(fp, 0, SEEK_END);
    long length = ftell(fp);
    fseek(fp, 0, SEEK_SET);

    char *json_str = (char *)malloc(length + 1);
    if (json_str == NULL) {
        printf("Memory allocation failed\n");
        fclose(fp);
        return 1;
    }

    fread(json_str, 1, length, fp);
    fclose(fp);
    json_str[length] = '\0';

    cJSON *json = cJSON_Parse(json_str);

    if (json == NULL) {
        printf("Error parsing JSON: %s\n", cJSON_GetErrorPtr());
        free(json_str);
        return 1;
    }

    const char *filter_key = "EUI";
    const int max_eui_count = 100; //TODO Maybe change later
    const char *eui_array[max_eui_count];
    int eui_count = 0;

    filterJSON(json, filter_key, eui_array, &eui_count);

    char *final_json = build_final_json(eui_array, eui_count);
    printf("%s\n", final_json);

    cJSON_free(final_json);
    cJSON_Delete(json);
    free(json_str);

    return 0;
}
