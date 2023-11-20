import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:powersync_flutter_demo/fts_helpers.dart';
import 'package:powersync_flutter_demo/models/todo_list.dart';

import './todo_list_page.dart';

final log = Logger('powersync-supabase');

class FtsSearchDelegate extends SearchDelegate {
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        onPressed: () {
          query = '';
        },
        icon: Icon(Icons.clear),
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () {
        close(context, null);
      },
      icon: Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return FutureBuilder<List>(
      future: _search(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return ListView.builder(
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(snapshot.data?[index].name),
                onTap: () {
                  close(context, null);
                },
              );
            },
            itemCount: snapshot.data?.length,
          );
        } else {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    NavigatorState navigator = Navigator.of(context);

    return FutureBuilder<List>(
      future: _search(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return ListView.builder(
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(snapshot.data?[index]['name'] ?? ''),
                onTap: () async {
                  TodoList list =
                      await TodoList.find(snapshot.data![index]['id']);
                  navigator.push(MaterialPageRoute(
                    builder: (context) => TodoListPage(list: list),
                  ));
                },
              );
            },
            itemCount: snapshot.data?.length,
          );
        } else {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }

  Future<List> _search() async {
    List listsSearchResults = await FtsHelpers.search(query, 'lists');
    List todoItemsSearchResults = await FtsHelpers.search(query, 'todos');
    List formattedListResults = listsSearchResults
        .map((result) => {"id": result['id'], "name": result['name']})
        .toList();
    List formattedTodoItemsResults = todoItemsSearchResults
        .map((result) => {
              // Use list_id so the navigation goes to the list page
              "id": result['list_id'],
              "name": result['description'],
            })
        .toList();
    List formattedResults = [
      ...formattedListResults,
      ...formattedTodoItemsResults
    ];
    return formattedResults;
  }
}
