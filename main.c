#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "cJSON.h"

char *build_final_json(const char *eui_array[], const char *device_name_array[], int eui_count) {
    cJSON *root = cJSON_CreateObject();
    cJSON *eui_json_array = cJSON_CreateArray();

    for (int i = 0; i < eui_count; i++) {
        cJSON *device_jsonobj = cJSON_CreateObject();
        cJSON_AddStringToObject(device_jsonobj, "Name", device_name_array[i]);
        cJSON_AddStringToObject(device_jsonobj, "EUI", eui_array[i]);
        cJSON_AddItemToArray(eui_json_array, device_jsonobj);
    }

    cJSON_AddItemToObject(root, "devices", eui_json_array);

    char *json_str = cJSON_Print(root);
    cJSON_Delete(root);

    return json_str;
}

int main() {
    FILE *fp = fopen("eui.json", "r");
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

    const int max_eui_count = 100; //TODO Maybe change later
    const char *eui_array[max_eui_count];
    const char *name_array[max_eui_count];
    int eui_count = 0;

    char *final_json = build_final_json(eui_array, name_array, eui_count);
    printf("%s\n", final_json);

    free(final_json);
    cJSON_Delete(json);
    free(json_str);

    return 0;
}
