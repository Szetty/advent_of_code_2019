// compiled with clang
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <limits.h>

#define NAME_SIZE 3

struct object {
    char *name;
};
typedef struct object object;

struct orbit {
    object from;
    object to;
};
typedef struct orbit orbit;

struct graph {
    object *objects;
    long objects_size;
    orbit *orbits;
    long orbits_size;
};
typedef struct graph graph;

long add_to_objects_set(object *objects, long objects_size, object object) {
    long i;
    for (i = 0; i < objects_size; i++) {
        if (!strcmp(object.name, objects[i].name)) {
            return objects_size;
        }
    }
    objects[objects_size] = object;
    return objects_size + 1;
}

graph build_graph(char *input, long size) {
    long orbits_size = size / 7;
    orbit *orbits = malloc(orbits_size * sizeof(orbit));
    object *temp_objects = malloc(2 * orbits_size * sizeof(object));
    long temp_objects_size = 0;

    for (long i = 0; i < size; i+=7) {
        char *name1 = malloc(NAME_SIZE + 1);
        char *name2 = malloc(NAME_SIZE + 1);
        memcpy(name1, input + i, NAME_SIZE);
        name1[NAME_SIZE] = '\0';
        memcpy(name2, input + i + 4, NAME_SIZE);
        name2[NAME_SIZE] = '\0';
        object object1 = {name1};
        object object2 = {name2};
        temp_objects_size = add_to_objects_set(temp_objects, temp_objects_size, object1);
        temp_objects_size = add_to_objects_set(temp_objects, temp_objects_size, object2);
        orbit orbit = {object1, object2};
        orbits[i / 7] = orbit;
    }

    object *objects = malloc(temp_objects_size * sizeof(object));
    memcpy(objects, temp_objects, temp_objects_size * sizeof(object));
    free(temp_objects);
    graph graph = {objects, temp_objects_size, orbits, orbits_size};
    return graph;
}

void print_graph(graph graph) {
    printf("%ld %ld\n", graph.orbits_size, graph.objects_size);
    for (long i = 0; i < graph.objects_size; i++) {
        printf("%s ", graph.objects[i].name);
    }
    printf("\n");
    for (long i = 0; i < graph.orbits_size; i++) {
        printf("%s -> %s\n", graph.orbits[i].from.name, graph.orbits[i].to.name);
    }
}

void destruct(graph graph) {
    for (long i = 0; i < graph.objects_size; i++) {
        free(graph.objects[i].name);
    }
    free(graph.orbits);
    free(graph.objects);
}

struct object_with_distance {
    object object;
    long distance;
};
typedef struct object_with_distance object_with_distance;

object_with_distance pop_object_with_smallest_distance(object_with_distance *objects_with_distance, long* size) {
    long min_distance = LONG_MAX;
    long min_index = -1;
    for (long i = 0; i < *size; i++) {
        if (objects_with_distance[i].distance < min_distance) {
            min_distance = objects_with_distance[i].distance;
            min_index = i;
        }
    }
    object_with_distance to_return = objects_with_distance[min_index];
    objects_with_distance[min_index] = objects_with_distance[*size - 1];
    objects_with_distance[*size - 1] = to_return;
    *size = *size - 1;
    return to_return;
}

void update_distance(object_with_distance *objects_with_distance, long size, object obj, long distance) {
    for (long i = 0; i < size; i++) {
        if (!strcmp(obj.name, objects_with_distance[i].object.name) && distance < objects_with_distance[i].distance) {
            objects_with_distance[i].distance = distance;
        }
    }
}

long shortest_distance(graph graph, object source, object destination) {
    long objects_with_distance_size = graph.objects_size;
    object_with_distance *objects_with_distance = malloc(objects_with_distance_size * sizeof(object_with_distance));
    for (long i = 0; i < objects_with_distance_size; i++) {
        long distance = LONG_MAX;
        if (!strcmp(source.name, graph.objects[i].name)) {
            distance = 0;
        }
        object_with_distance object_with_distance = {graph.objects[i], distance};
        objects_with_distance[i] = object_with_distance;
    }
    long min_distance = LONG_MAX;
    while (objects_with_distance_size > 0) {
        object_with_distance object_with_min_distance = pop_object_with_smallest_distance(objects_with_distance, &objects_with_distance_size);
        if (!strcmp(destination.name, object_with_min_distance.object.name)) {
            min_distance = object_with_min_distance.distance;
            break;
        }
        for (long i = 0; i < graph.orbits_size; i++) {
            object neighbour;
            if (!strcmp(object_with_min_distance.object.name, graph.orbits[i].from.name)) {
                update_distance(objects_with_distance, objects_with_distance_size, graph.orbits[i].to, object_with_min_distance.distance + 1);
            }
            if (!strcmp(object_with_min_distance.object.name, graph.orbits[i].to.name)) {
                update_distance(objects_with_distance, objects_with_distance_size, graph.orbits[i].from, object_with_min_distance.distance + 1);
            }
        }
    }
    free(objects_with_distance);
    return min_distance;
}

long remove_object(object *objects, long objects_size, object obj) {
    long i;
    for (i = 0; i < objects_size; i++) {
        if (!strcmp(obj.name, objects[i].name)) {
            object aux = objects[objects_size - 1];
            objects[objects_size - 1] = objects[i];
            objects[i] = aux;
            return objects_size - 1;
        }
    }
    
    return objects_size;
}

long find_not_orbiting_objects(graph graph, object** not_orbiting_objects) {
    if (*not_orbiting_objects != NULL) {
        free(*not_orbiting_objects);
    }
    long temp_object_size = graph.objects_size ;
    object *temp_objects = malloc(temp_object_size * sizeof(object));
    memcpy(temp_objects, graph.objects, temp_object_size * sizeof(object));
    for (long i = 0; i < graph.orbits_size; i++) {
        temp_object_size = remove_object(temp_objects, temp_object_size, graph.orbits[i].to);
    }
    *not_orbiting_objects = malloc(temp_object_size * sizeof(object));
    memcpy(*not_orbiting_objects, temp_objects, temp_object_size * sizeof(object));
    free(temp_objects);
    return temp_object_size;
}

struct object_with_count {
    object object;
    long count;
};
typedef struct object_with_count object_with_count;

void add_current_count_to_next_object(object_with_count *objects_with_count, long objects_with_count_size, object current_object, object next_object) {
    long next_object_index = -1;
    long current_count = -1;
    for (long i = 0; i < objects_with_count_size; i++) {
        if (!strcmp(objects_with_count[i].object.name, current_object.name)) {
            current_count = objects_with_count[i].count;
        }
        if (!strcmp(objects_with_count[i].object.name, next_object.name)) {
            next_object_index = i;
        }
    }
    objects_with_count[next_object_index].count += current_count + 1;
}

long remove_orbit(orbit *orbits, long orbits_size, long index) {
    if (index < orbits_size) {
        orbit aux = orbits[orbits_size - 1];
        orbits[orbits_size - 1] = orbits[index];
        orbits[index] = aux;
        return orbits_size - 1; 
    }
    
    return orbits_size;
}

long count_all_orbits(graph graph) {
    long objects_with_count_size = graph.objects_size;
    object_with_count *objects_with_count = malloc(objects_with_count_size * sizeof(object_with_count));
    for (long i = 0; i < objects_with_count_size; i++) {
        object_with_count object_with_count = {graph.objects[i], 0};
        objects_with_count[i] = object_with_count;
    }
    object* not_orbiting_objects = NULL;
    long not_orbiting_objects_size = find_not_orbiting_objects(graph, &not_orbiting_objects);
    while (not_orbiting_objects_size > 0) {
        for (long i = 0; i < not_orbiting_objects_size; i++) {
            object current_object = not_orbiting_objects[i];
            long* to_remove = malloc(graph.orbits_size * sizeof(long));
            long to_remove_size = 0;
            for (long j = 0; j < graph.orbits_size; j++) {
                if (!strcmp(graph.orbits[j].from.name, current_object.name)) {
                    add_current_count_to_next_object(objects_with_count, objects_with_count_size, current_object, graph.orbits[j].to);
                    to_remove[to_remove_size++] = j;
                }
            }
            for (long j = 0; j < to_remove_size; j++) {
                long index = to_remove[j];
                graph.orbits_size = remove_orbit(graph.orbits, graph.orbits_size, index);
            }
            free(to_remove);
            graph.objects_size = remove_object(graph.objects, graph.objects_size, current_object);
        }
        not_orbiting_objects_size = find_not_orbiting_objects(graph, &not_orbiting_objects);
    }
    long sum = 0;
    for (long i = 0; i < objects_with_count_size; i++) {
        sum += objects_with_count[i].count;
    }
    return sum;
}

long read_input(char **input) {
    FILE* file;
    long i, file_size, k;
    char* file_content;

    file = fopen("inputs/6","r");
    fseek(file, 0, SEEK_END);
    file_size = ftell(file);
    fseek(file, 0, SEEK_SET);
    file_content = (char *) malloc(file_size);
    k = 0;
    for (i = 0; i < file_size; i++) {
        char c = (char) fgetc(file);
        if (c != '\n') {
            file_content[k++] = c;
        }
    }
    *input = (char*) malloc(k);
    memcpy(*input, file_content, k);
    free(file_content);
    fclose(file);
    return k;
}

void test_shortest_distance() {
    char *test = "COM)BBBBBB)CCCCCC)DDDDDD)EEEEEE)FFFBBB)GGGGGG)HHHDDD)IIIEEE)JJJJJJ)KKKKKK)LLLKKK)YOUIII)SAN";
    graph graph = build_graph(test, strlen(test));
    object source = {"YOU"};
    object destination = {"SAN"};
    assert(shortest_distance(graph, source, destination) == 6);
    destruct(graph);
}

void test_count_all_orbits() {
    char *test = "COM)BBBBBB)CCCCCC)DDDDDD)EEEEEE)FFFBBB)GGGGGG)HHHDDD)IIIEEE)JJJJJJ)KKKKKK)LLL";
    graph graph = build_graph(test, strlen(test));
    assert(count_all_orbits(graph) == 42);
    destruct(graph);
}

int main() {
    test_count_all_orbits();
    test_shortest_distance();

    char *input;
    long size = read_input(&input);
    graph graph = build_graph(input, size);
    free(input);
    printf("%ld\n", count_all_orbits(graph));
    object source = {"YOU"};
    object destination = {"SAN"};
    printf("%ld\n", shortest_distance(graph, source, destination) - 2);
    destruct(graph);

    return 0;
}