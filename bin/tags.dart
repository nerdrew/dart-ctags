import 'dart:async';
import 'dart:io';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart' as an;
import 'package:path/path.dart' as path;
import 'package:args/args.dart';

class Ctags {
  ArgResults options;

  // /./ in dart/js does not match newlines, /[^]/ matches . + \n
  RegExp klass = RegExp(r'^[^]+?($|{)');
  RegExp constructor = RegExp(r'^[^]+?($|{|;)');
  RegExp method = RegExp(r'^[^]+?($|{|;|\=>)');

  Ctags(this.options);

  generate() {
    Iterable<String> dirs;

    if (options.rest.isEmpty) {
      dirs = ['.'];
    } else {
      dirs = options.rest;
    }

    List<String> lines = [
      '!_TAG_FILE_FORMAT\t2\t/extended format; --format=1 will not append ;" to lines/',
      '!_TAG_FILE_SORTED\t1\t/0=unsorted, 1=sorted, 2=foldcase/'
    ];

    Future.wait(dirs.map(addFileSystemEntity))
        .then((Iterable<Iterable<Iterable<String>>> files) {
      files.forEach((Iterable<Iterable<String>> file) {
        file.forEach((Iterable<String> fileLines) => lines.addAll(fileLines));
      });

      if (!(options['skip-sort'] as bool)) {
        lines.sort();
      }
      if (options['output'] != null) {
        File(options['output'] as String).writeAsString(lines.join('\n'));
      } else {
        print(lines.join('\n'));
      }
    });
  }

  Future<Iterable<Iterable<String>>> addFileSystemEntity(String name) {
    FileSystemEntityType type = FileSystemEntity.typeSync(name);

    if (type == FileSystemEntityType.directory) {
      return Directory(name)
          .list(recursive: true, followLinks: options['follow-links'] as bool)
          .map((file) {
        if (file is File && path.extension(file.path) == '.dart') {
          return parseFile(file);
        } else {
          return <String>[];
        }
      }).toList();
    } else if (type == FileSystemEntityType.file) {
      return Future.value([parseFile(File(name))]);
    } else if (type == FileSystemEntityType.link &&
        options['follow-links'] as bool) {
      return addFileSystemEntity(Link(name).targetSync());
    } else {
      return Future.value([]);
    }
  }

  Iterable<String> parseFile(File file) {
    if (!(options['include-hidden'] as bool) &&
        path.split(file.path).any((name) => name[0] == '.' && name != '.')) {
      return [];
    }

    String root;
    if (options['output'] != null) {
      root = path.relative(path.dirname(options['output'] as String));
    } else {
      root = '.';
    }

    List<List<String>> lines = [];
    var result = an.parseFile(
        path: file.path, featureSet: FeatureSet.fromEnableFlags([]));
    var unit = result.unit;
    unit.declarations.forEach((declaration) {
      if (declaration is FunctionDeclaration) {
        lines.add([
          declaration.name.name,
          path.relative(file.path, from: root),
          '/^;"',
          'f',
          options['line-numbers'] as bool
              ? 'line:${unit.lineInfo.getLocation(declaration.offset).lineNumber}'
              : ''
        ]);
      } else if (declaration is ClassDeclaration) {
        lines.add([
          declaration.name.name,
          path.relative(file.path, from: root),
          '/${klass.matchAsPrefix(declaration.toSource())[0]}/;"',
          'c',
          options['line-numbers'] as bool
              ? 'line:${unit.lineInfo.getLocation(declaration.offset).lineNumber}'
              : ''
        ]);
        declaration.members.forEach((member) {
          if (member is ConstructorDeclaration) {
            lines.add([
              member.name == null ? declaration.name.name : member.name.name,
              path.relative(file.path, from: root),
              '/${constructor.matchAsPrefix(member.toSource())[0]}/;"',
              'M',
              options['line-numbers'] as bool
                  ? 'line:${unit.lineInfo.getLocation(member.offset).lineNumber}'
                  : '',
              'class:${declaration.name}'
            ]);
          } else if (member is FieldDeclaration) {
            member.fields.variables.forEach((variable) {
              lines.add([
                variable.name.name,
                path.relative(file.path, from: root),
                '/${member.toSource()}/;"',
                'i',
                options['line-numbers'] as bool
                    ? 'line:${unit.lineInfo.getLocation(member.offset).lineNumber}'
                    : '',
                'class:${declaration.name}'
              ]);
            });
          } else if (member is MethodDeclaration) {
            lines.add([
              member.name.name,
              path.relative(file.path, from: root),
              '/${method.matchAsPrefix(member.toSource())[0]}/;"',
              member.isStatic ? 'M' : 'm',
              options['line-numbers'] as bool
                  ? 'line:${unit.lineInfo.getLocation(member.offset).lineNumber}'
                  : '',
              'class:${declaration.name}'
            ]);
          }
        });
      }
    });
    return lines.map((line) => line.join('\t'));
  }
}

main([List<String> args]) {
  ArgParser parser = ArgParser();
  parser.addOption('output',
      abbr: 'o',
      help: 'Output file for tags (default: stdout)',
      valueHelp: 'FILE');
  parser.addFlag('follow-links',
      help: 'Follow symbolic links (default: false)', negatable: false);
  parser.addFlag('include-hidden',
      help: 'Include hidden directories (default: false)', negatable: false);
  parser.addFlag('line-numbers',
      abbr: 'l',
      help: 'Add line numbers to extension fields (default: false)',
      negatable: false);
  parser.addFlag('skip-sort',
      help: 'Skip sorting the output (default: false)', negatable: false);
  parser.addFlag('help', abbr: 'h', help: 'Show this help', negatable: false);
  ArgResults options = parser.parse(args);
  if (options['help'] as bool) {
    print(
        'Usage:\n\tpub global run dart_ctags:tags [OPTIONS] [FILES...]\n\tpub run tags [OPTIONS] [FILES...]\n');
    print(parser.usage);
    exit(0);
  }
  Ctags(options).generate();
}
