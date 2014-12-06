import 'dart:async';
import 'dart:io';
import 'package:analyzer/analyzer.dart';
import 'package:path/path.dart' as path;
import 'package:args/args.dart';

class Ctags {
  ArgResults options;

  RegExp klass = new RegExp(r'^.+?($|{)');
  RegExp constructor = new RegExp(r'^.+?($|{|;)');
  RegExp method = new RegExp(r'^.+?($|{|;|\=>)');

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
        '!_TAG_FILE_SORTED\t1\t/0=unsorted, 1=sorted, 2=foldcase/'];

    Future.wait(dirs.map(addFileSystemEntity)).then((Iterable<Iterable<Iterable<String>>> files) {
      files.forEach((Iterable<Iterable<String>> file) {
        file.forEach((Iterable<String> fileLines) => lines.addAll(fileLines));
      });

      if (!options['skip-sort']) {
        lines.sort();
      }
      if (options['output'] != null) {
        new File(options['output']).writeAsString(lines.join('\n'));
      } else {
        print(lines.join('\n'));
      }
    });
  }

  Future<Iterable<Iterable<String>>> addFileSystemEntity(name) {
    FileSystemEntityType type = FileSystemEntity.typeSync(name);

    if (type == FileSystemEntityType.DIRECTORY) {
      return new Directory(
          name).list(recursive: true, followLinks: options['follow-links']).map((file) {
        if (file is File && path.extension(file.path) == '.dart') {
          return parseFile(file);
        } else {
          return [];
        }
      }).toList();
    } else if (type == FileSystemEntityType.FILE) {
      return new Future.value([parseFile(new File(name))]);
    } else if (type == FileSystemEntityType.LINK && options['follow-links']) {
      return addFileSystemEntity(new Link(name).targetSync());
    }
  }

  Iterable<String> parseFile(File file) {
    if (!options['include-hidden'] &&
        path.split(file.path).any((name) => name[0] == '.' && name != '.')) {
      return [];
    }

    String root;
    if (options['output'] != null) {
      root = path.relative(path.dirname(options['output']));
    } else {
      root = '.';
    }

    List<List<String>> lines = [];
    CompilationUnit unit = parseDartFile(file.path);
    var lineInfo = unit.lineInfo;
    unit.declarations.forEach((declaration) {
      if (declaration is FunctionDeclaration) {
        lines.add(
            [
                declaration.name,
                path.relative(file.path, from: root),
                '/^;"',
                'f',
                options['line-numbers'] ? 'line:${lineInfo.getLocation(declaration.offset).lineNumber}' : '']);
      } else if (declaration is ClassDeclaration) {
        lines.add(
            [
                declaration.name,
                path.relative(file.path, from: root),
                '/${klass.matchAsPrefix(declaration.toSource())[0]}/;"',
                'c',
                options['line-numbers'] ? 'line:${lineInfo.getLocation(declaration.offset).lineNumber}' : '']);
        declaration.members.forEach((member) {
          if (member is ConstructorDeclaration) {
            lines.add(
                [
                    member.name == null ? declaration.name : member.name,
                    path.relative(file.path, from: root),
                    '/${constructor.matchAsPrefix(member.toSource())[0]}/;"',
                    'M',
                    'class:${declaration.name}',
                    options['line-numbers'] ? 'line:${lineInfo.getLocation(member.offset).lineNumber}' : '']);
          } else if (member is FieldDeclaration) {
            member.fields.variables.forEach((variable) {
              lines.add(
                  [
                      variable.name,
                      path.relative(file.path, from: root),
                      '/${member.toSource()}/;"',
                      'i',
                      'class:${declaration.name}',
                      options['line-numbers'] ? 'line:${lineInfo.getLocation(member.offset).lineNumber}' : '']);
            });
          } else if (member is MethodDeclaration) {
            lines.add(
                [
                    member.name,
                    path.relative(file.path, from: root),
                    '/${method.matchAsPrefix(member.toSource())[0]}/;"',
                    member.isStatic ? 'M' : 'm',
                    'class:${declaration.name}',
                    options['line-numbers'] ? 'line:${lineInfo.getLocation(member.offset).lineNumber}' : '']);
          }
        });
      }
    });
    return lines.map((line) => line.join('\t'));
  }
}

main([List<String> args]) {
  ArgParser parser = new ArgParser();
  parser.addOption(
      'output',
      abbr: 'o',
      help: 'Output file for tags (default: stdout)',
      valueHelp: 'FILE');
  parser.addFlag('follow-links', help: 'Follow symbolic links (default: false)', negatable: false);
  parser.addFlag(
      'include-hidden',
      help: 'Include hidden directories (default: false)',
      negatable: false);
  parser.addFlag(
      'line-numbers',
      abbr: 'l',
      help: 'Add line numbers to extension fields (default: false)',
      negatable: false);
  parser.addFlag('skip-sort', help: 'Skip sorting the output (default: false)', negatable: false);
  parser.addFlag('help', abbr: 'h', help: 'Show this help', negatable: false);
  ArgResults options = parser.parse(args);
  if (options['help']) {
    print(
        'Usage:\n\tpub global run dart_ctags:tags [OPTIONS] [FILES...]\n\tpub run tags [OPTIONS] [FILES...]\n');
    print(parser.getUsage());
    exit(0);
  }
  new Ctags(options).generate();
}
