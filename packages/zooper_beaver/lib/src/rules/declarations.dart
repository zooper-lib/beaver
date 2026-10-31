/// Declarations: compilation unit, directives, classes and other type
/// declarations, members, functions, variables, parameters, metadata.
library;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/token.dart';

import '../config/config.dart';
import '../ir/doc.dart';
import 'builder.dart';
import 'expressions.dart';
import 'lists.dart';
import 'statements.dart';

extension DeclarationRules on DocBuilder {
  Doc? buildDeclaration(AstNode node) => switch (node) {
    CompilationUnit() => compilationUnit(node),
    ClassDeclaration() => typeDeclaration(node, node.body),
    MixinDeclaration() => typeDeclaration(node, node.body),
    ExtensionDeclaration() => typeDeclaration(node, node.body),
    ExtensionTypeDeclaration() => typeDeclaration(node, node.body),
    EnumDeclaration() => typeDeclaration(node, node.body),
    ClassTypeAlias() => declarationHeader(node),
    BlockClassBody() => classBody(
      node.leftBracket,
      node.members,
      node.rightBracket,
    ),
    EmptyClassBody() => tok(node.semicolon),
    BlockEnumBody() => enumBody(node),
    EmptyEnumBody() => tok(node.semicolon),
    NameWithTypeParameters() => concat([
      tok(node.typeName),
      visit(node.typeParameters),
    ]),
    ExtendsClause() => concat([
      tok(node.extendsKeyword),
      space,
      visit(node.superclass),
    ]),
    WithClause() => typeClause(node.withKeyword, node.mixinTypes),
    ImplementsClause() => typeClause(node.implementsKeyword, node.interfaces),
    MixinOnClause() => typeClause(node.onKeyword, node.superclassConstraints),
    ExtensionOnClause() => concat([
      tok(node.onKeyword),
      space,
      visit(node.extendedType),
    ]),
    MethodDeclaration() => declarationHeader(node),
    FunctionDeclaration() => declarationHeader(node),
    ConstructorDeclaration() => constructor(node),
    FieldDeclaration() => declarationHeader(node),
    TopLevelVariableDeclaration() => declarationHeader(node),
    GenericTypeAlias() => declarationHeader(node),
    FunctionTypeAlias() => declarationHeader(node),
    VariableDeclarationList() => variableList(node),
    VariableDeclaration() => node.initializer == null
        ? tok(node.name)
        : assignmentLike(tok(node.name), node.equals!, node.initializer!),
    FunctionExpression() => functionExpression(node),
    BlockFunctionBody() => concat([
      if (node.keyword != null) ...[tok(node.keyword), tok(node.star), space],
      visit(node.block),
    ]),
    ExpressionFunctionBody() => concat([
      if (node.keyword != null) ...[tok(node.keyword), tok(node.star), space],
      assignmentRhs(node.functionDefinition, node.expression),
      tok(node.semicolon),
    ]),
    EmptyFunctionBody() => tok(node.semicolon),
    FormalParameterList() => parameterList(node),
    FormalParameter() => declarationHeader(node, inlineMetadata: true),
    FormalParameterDefaultClause() => node.separator.type == TokenType.EQ
        ? assignmentRhs(node.separator, node.value)
        : concat([tok(node.separator), space, visit(node.value)]),
    FunctionTypedFormalParameterSuffix() => concat([
      visit(node.typeParameters),
      visit(node.formalParameters),
      tok(node.question),
    ]),
    TypeParameterList() => delimited(
      open: node.leftBracket,
      items: node.typeParameters,
      close: node.rightBracket,
      settings: config.parameters.unaligned,
      optionalTrailingComma: false,
    ),
    TypeParameter() => declarationHeader(node, inlineMetadata: true),
    Annotation() => concat([
      tok(node.atSign),
      visit(node.name),
      visit(node.typeArguments),
      tok(node.period),
      visit(node.constructorName),
      visit(node.arguments),
    ]),
    EnumConstantDeclaration() => declarationHeader(node),
    ConstructorFieldInitializer() => assignmentLike(
      concat([tok(node.thisKeyword), tok(node.period), visit(node.fieldName)]),
      node.equals,
      node.expression,
    ),
    SuperConstructorInvocation() => concat([
      tok(node.superKeyword),
      tok(node.period),
      visit(node.constructorName),
      visit(node.argumentList),
    ]),
    RedirectingConstructorInvocation() => concat([
      tok(node.thisKeyword),
      tok(node.period),
      visit(node.constructorName),
      visit(node.argumentList),
    ]),
    AssertInitializer() => assertion(node),
    PrimaryConstructorDeclaration() => concat([
      if (node.constKeyword != null) ...[tok(node.constKeyword), space],
      tok(node.typeName),
      visit(node.typeParameters),
      visit(node.constructorName),
      visit(node.formalParameters),
    ]),
    PrimaryConstructorName() => concat([tok(node.period), tok(node.name)]),
    PrimaryConstructorBody() => concat([
      metadata(node),
      tok(node.thisKeyword),
      if (node.initializers.isNotEmpty)
        initializerList(node.colon!, node.initializers),
      if (node.body is! EmptyFunctionBody) space,
      visit(node.body),
    ]),
    ImportDirective() => directive(
      node,
      [
        tok(node.importKeyword),
        space,
        visit(node.uri),
        for (final c in node.configurations) ...[line, visit(c)],
        if (node.deferredKeyword != null) ...[space, tok(node.deferredKeyword)],
        if (node.asKeyword != null) ...[
          space,
          tok(node.asKeyword),
          space,
          visit(node.prefix),
        ],
      ],
      node.combinators,
      node.semicolon,
    ),
    ExportDirective() => directive(
      node,
      [
        tok(node.exportKeyword),
        space,
        visit(node.uri),
        for (final c in node.configurations) ...[line, visit(c)],
      ],
      node.combinators,
      node.semicolon,
    ),
    PartDirective() => directive(
      node,
      [tok(node.partKeyword), space, visit(node.uri)],
      const [],
      node.semicolon,
    ),
    PartOfDirective() => directive(
      node,
      [
        tok(node.partKeyword),
        space,
        tok(node.ofKeyword),
        space,
        visit(node.libraryName),
        visit(node.uri),
      ],
      const [],
      node.semicolon,
    ),
    LibraryDirective() => directive(
      node,
      [
        tok(node.libraryKeyword),
        if (node.name != null) ...[space, visit(node.name)],
      ],
      const [],
      node.semicolon,
    ),
    DottedName() => concat([
      for (
        Token? t = node.beginToken;
        t != null && t.offset < node.end;
        t = t.next
      )
        tok(t),
    ]),
    Configuration() => concat([
      tok(node.ifKeyword),
      space,
      tok(node.leftParenthesis),
      visit(node.name),
      if (node.equalToken != null) ...[
        space,
        tok(node.equalToken),
        space,
        visit(node.value),
      ],
      tok(node.rightParenthesis),
      space,
      visit(node.uri),
    ]),
    ShowCombinator() => combinator(node.keyword, node.shownNames),
    HideCombinator() => combinator(node.keyword, node.hiddenNames),
    ScriptTag() => generic(node),
    EnumConstantArguments() => concat([
      visit(node.typeArguments),
      visit(node.constructorSelector),
      visit(node.argumentList),
    ]),
    ConstructorSelector() => concat([tok(node.period), visit(node.name)]),
    _ => null,
  };

  Doc compilationUnit(CompilationUnit node) {
    final members = node.sortedDirectivesAndDeclarations;
    final scriptTag = node.scriptTag;
    final eof = danglingLines(node.endToken);
    return concat([
      if (scriptTag != null) ...[
        visit(scriptTag),
        if (members.isNotEmpty) ...[hardline, hardline],
      ],
      sequence(members, blankLines: _topLevelBlankLines),
      if (eof != null) ...[if (members.isNotEmpty) hardline, eof],
      hardline,
    ]);
  }

  int? _topLevelBlankLines(AstNode previous, AstNode next, int sourceBlank) {
    if (previous is Directive && next is! Directive) {
      return config.blankLinesAfterImports;
    }
    if (previous is Directive && next is Directive) {
      final count = config.values['blank_lines.between_import_groups'];
      final (a, b) = (_directiveGroup(previous), _directiveGroup(next));
      return count is int && a != null && b != null && a != b ? count : null;
    }
    if ((_isClassLike(previous) || _isClassLike(next)) &&
        config.settings['blank_lines.around_class_declarations'] != 'inherit') {
      return config.blankLinesAroundClasses;
    }
    // Two declarations without a block body keep their source grouping.
    if (config.flag(
          'blank_lines.keep_between_non_block_top_level_declarations',
        ) &&
        !_hasBlockBody(previous) &&
        !_hasBlockBody(next)) {
      return null;
    }
    final count = config.values['blank_lines.between_top_level_declarations'];
    return count is int ? count : null;
  }

  /// `dart:`, `package:` and relative imports, exports and parts are the
  /// groups `blank_lines.between_import_groups` separates.
  static String? _directiveGroup(AstNode directive) => switch (directive) {
    ImportDirective(:final uri) => switch (uri.stringValue) {
      final u? when u.startsWith('dart:') => 'dart',
      final u? when u.startsWith('package:') => 'package',
      _ => 'relative',
    },
    ExportDirective() => 'export',
    PartDirective() => 'part',
    _ => null,
  };

  static bool _isClassLike(AstNode node) =>
      node is ClassDeclaration ||
      node is MixinDeclaration ||
      node is EnumDeclaration ||
      node is ExtensionDeclaration ||
      node is ExtensionTypeDeclaration;

  /// Annotations, placed per `wrap.annotations`, or inline for parameters.
  Doc metadata(AnnotatedNode node, {bool inline = false}) {
    final placement = config.values['wrap.annotations'];
    return concat([
      for (final annotation in node.metadata) ...[
        visit(annotation),
        if (inline || placement == 'same_line')
          space
        else if (placement == 'preserve' &&
            newlinesBetween(annotation.end, annotation.endToken.next!.offset) ==
                0)
          space
        else
          hardline,
      ],
    ]);
  }

  /// A declaration printed child by child with single spaces, except where
  /// tokens attach (`name(`, `name<`, `this.x`, `int?`). Clauses (`extends`,
  /// `with`, ...) may wrap with continuation indentation.
  Doc declarationHeader(AnnotatedNode node, {bool inlineMetadata = false}) {
    final parts = <(SyntacticEntity, Doc, Doc)>[];
    final tail = <Doc>[];
    SyntacticEntity? previous;
    for (final child in node.childEntities) {
      if (child is Comment || child is Annotation) continue;
      final separator = previous == null ? empty : _separator(previous, child);
      if (child is FunctionBody) {
        // The body is not part of the header's continuation.
        tail.addAll([_beforeBody(child), visit(child)]);
      } else if (child is FunctionExpression) {
        // `name` + `<T>(params) body`.
        tail.addAll([
          visit(child.typeParameters),
          visit(child.parameters),
          _beforeBody(child.body),
          visit(child.body),
        ]);
      } else {
        parts.add((child, separator, _entity(child)));
      }
      previous = child;
    }
    return concat([
      metadata(node, inline: inlineMetadata),
      group(_header(parts)),
      ...tail,
    ]);
  }

  Doc _separator(SyntacticEntity previous, SyntacticEntity next) {
    if (_glued(previous, next)) return empty;
    if (_isClause(next)) return line;
    return space;
  }

  Doc _entity(SyntacticEntity entity) =>
      entity is AstNode ? visit(entity) : tok(entity as Token);

  static bool _isClause(SyntacticEntity entity) =>
      entity is ExtendsClause ||
      entity is WithClause ||
      entity is ImplementsClause ||
      entity is MixinOnClause ||
      entity is ExtensionOnClause ||
      entity is NativeClause;

  /// Header parts with each clause (and the line before it) under
  /// continuation indent; other parts are not indented.
  Doc _header(List<(SyntacticEntity, Doc, Doc)> parts) => concat([
    for (final (entity, separator, doc) in parts)
      _isClause(entity)
          ? cont(concat([separator, doc]))
          : concat([separator, doc]),
  ]);

  bool _glued(SyntacticEntity previous, SyntacticEntity next) {
    if (next is TypeParameterList ||
        next is FormalParameterList ||
        next is TypeArgumentList ||
        next is ArgumentList ||
        next is FunctionTypedFormalParameterSuffix ||
        next is EnumConstantArguments ||
        next is EmptyFunctionBody) {
      return true;
    }
    if (next is Token) {
      final type = next.type;
      if (type == TokenType.SEMICOLON ||
          type == TokenType.PERIOD ||
          type == TokenType.QUESTION ||
          type == TokenType.COMMA) {
        return true;
      }
    }
    if (previous is Token && previous.type == TokenType.PERIOD) return true;
    // `operator ==`
    return false;
  }

  /// `import 'uri' ... show a, b;`: configurations and combinators wrap
  /// with continuation indent, each combinator's names chopping on its own.
  Doc directive(
    Directive node,
    List<Doc> head,
    List<Combinator> combinators,
    Token semicolon,
  ) => concat([
    metadata(node),
    group(
      concat([
        cont(concat(head)),
        if (combinators.isNotEmpty)
          cont(
            concat([
              for (final c in combinators) ...[line, visit(c)],
            ]),
          ),
      ]),
    ),
    tok(semicolon),
  ]);

  Doc combinator(Token keyword, List<AstNode> names) => group(
    concat([
      tok(keyword),
      cont(concat([line, commaSeparated(names)])),
    ]),
  );

  /// `: a = b, c = d`. When the parameter list in [header] split, the
  /// initializers follow `) : ` one per line, lined up under the first.
  /// `: a = 1, b = 2` per `wrap.initializer_lists`. [header] is the
  /// constructor header's group: under `colon: auto`, when it split the colon
  /// follows `)` and the initializers align after it.
  Doc initializerList(
    Token colon,
    List<ConstructorInitializer> initializers, {
    GroupId? header,
  }) {
    final settings = config.initializerLists;
    var policy = settings.policy;
    if (policy == WrapPolicy.never &&
        hasLineCommentIn(colon.end, initializers.last.end)) {
      policy = WrapPolicy.chopIfLong;
    }
    final never = policy == WrapPolicy.never;
    final forced =
        !never &&
        (policy == WrapPolicy.chopAlways ||
            settings.reachesThreshold(initializers.length));
    final kept = [
      for (final (i, initializer) in initializers.indexed)
        i > 0 &&
            !never &&
            settings.keepExistingLineBreaks &&
            newlinesBetween(
                  initializers[i - 1].endToken.next!.end,
                  startWithComments(initializer),
                ) >
                0,
    ];
    // Built once: they may carry comments, and only one branch prints.
    final colonDoc = tok(colon);
    final spaced = config.flag('spaces.before_colon_in_initializer_list');
    final beforeColon = spaced ? space : empty;
    final items = [
      for (final (i, initializer) in initializers.indexed)
        concat([
          visit(initializer),
          if (i < initializers.length - 1) ...[
            if (config.spaceBeforeComma) space,
            tok(initializer.endToken.next),
          ],
        ]),
    ];
    final afterComma = config.spaceAfterComma ? ' ' : '';
    final list = runs(
      items,
      kept,
      separator: never
          ? Text(afterComma)
          : forced
          ? hardline
          : Line.soft(afterComma),
      fill: policy == WrapPolicy.ifLong && !forced,
    );
    if (never) return concat([beforeColon, colonDoc, space, list]);

    final width = settings.indent;
    // Later initializers under the first, or [width] past the baseline.
    Doc afterColon(Doc list) =>
        settings.align ? align(2, list) : indentBy(width, list);
    final newLine = group(
      indentBy(
        width,
        concat([
          Line.soft(spaced ? ' ' : ''),
          colonDoc,
          space,
          afterColon(list),
        ]),
      ),
    );
    switch (config.values['wrap.initializer_lists.colon']) {
      case 'new_line':
        return newLine;
      case 'end_of_header':
        final broken = concat([line, list]);
        return group(
          concat([
            beforeColon,
            colonDoc,
            indentBy(
              width,
              settings.align ? broken : indentBy(width, broken),
            ),
          ]),
        );
    }
    if (header == null) return newLine;
    final afterHeader = group(
      list,
      shouldBreak: initializers.length > 1,
    );
    return IfBreak(
      concat([
        beforeColon,
        colonDoc,
        space,
        settings.align
            ? alignToColumn(afterHeader)
            : indentBy(width, indentBy(width, afterHeader)),
      ]),
      newLine,
      header,
    );
  }

  Doc typeDeclaration(AnnotatedNode node, AstNode body) {
    final parts = <(SyntacticEntity, Doc, Doc)>[];
    SyntacticEntity? previous;
    for (final child in node.childEntities) {
      if (child is Comment || child is Annotation || identical(child, body)) {
        continue;
      }
      final separator = previous == null ? empty : _separator(previous, child);
      parts.add((child, separator, _entity(child)));
      previous = child;
    }
    return concat([
      metadata(node),
      _classHeader(parts),
      if (body is! EmptyClassBody && body is! EmptyEnumBody) space,
      visit(body),
    ]);
  }

  /// A type declaration's header with its `extends`, `with`, `implements`
  /// and `on` clauses laid out per `wrap.class_header`.
  Doc _classHeader(List<(SyntacticEntity, Doc, Doc)> parts) {
    final clauses = [
      for (final part in parts)
        if (_isClause(part.$1)) part,
    ];
    if (clauses.isEmpty) return group(_header(parts));
    final head = _header(parts.where((p) => !_isClause(p.$1)).toList());
    final settings = config.classHeader;
    var policy = settings.policy;
    final first = clauses.first.$1 as AstNode;
    final last = clauses.last.$1 as AstNode;
    if (policy == WrapPolicy.never &&
        hasLineCommentIn(first.offset, last.end)) {
      policy = WrapPolicy.chopIfLong;
    }
    final never = policy == WrapPolicy.never;
    final forced =
        !never &&
        (policy == WrapPolicy.chopAlways ||
            settings.reachesThreshold(clauses.length));
    final kept = [
      for (final (entity, _, _) in clauses)
        !never &&
            settings.keepExistingLineBreaks &&
            newlinesBetween(
                  (entity as AstNode).beginToken.previous!.end,
                  entity.offset,
                ) >
                0,
    ];
    // `extends` may stay on the name's line.
    final extendsStays =
        !config.flag('wrap.class_header.clauses_on_new_line') &&
        first is ExtendsClause;
    Doc separator(int i) => never || (i == 0 && extendsStays)
        ? space
        : forced
        ? hardline
        : line;
    final docs = [for (final (_, _, doc) in clauses) doc];
    // A kept break breaks the whole header, the layout it produces, so the
    // next run lays it out the same way.
    final broken = forced || kept.contains(true);
    return group(
      concat([
        head,
        if (policy == WrapPolicy.ifLong && !broken)
          cont(
            Fill([
              empty,
              for (var i = 0; i < docs.length; i++) ...[separator(i), docs[i]],
            ]),
          )
        else
          for (var i = 0; i < docs.length; i++)
            cont(concat([separator(i), docs[i]])),
      ]),
      shouldBreak: broken,
    );
  }

  Doc typeClause(Token keyword, List<AstNode> types) =>
      concat([tok(keyword), space, commaSeparated(types)]);

  Doc classBody(Token open, List<ClassMember> members, Token close) {
    if (members.isEmpty) return braces(open, null, close);
    return braces(
      open,
      concat([
        for (var b = 0; b < config.blankLinesBeforeFirstMember; b++) hardline,
        sequence(members, blankLines: _memberBlankLines),
      ]),
      close,
      after: config.blankLinesAfterLastMember,
    );
  }

  /// `between_members` applies around members with a `{ }` body; between
  /// two members without one (fields, `=>` members, constructors ending in
  /// `;`) the source's grouping is kept, up to the cap.
  int _memberBlankLines(AstNode previous, AstNode next, int sourceBlank) {
    if (config.flag('blank_lines.keep_between_non_block_members') &&
        !_hasBlockBody(previous) &&
        !_hasBlockBody(next)) {
      return capBlank(sourceBlank);
    }
    return config.blankLinesBetweenMembers;
  }

  /// Whether [declaration] has a `{ }` body of its own, syntactically: a
  /// variable initialised with a block-bodied closure has none.
  bool _hasBlockBody(AstNode declaration) => switch (declaration) {
    MethodDeclaration(:final body) || ConstructorDeclaration(:final body) =>
      body is BlockFunctionBody,
    FunctionDeclaration(:final functionExpression) =>
      functionExpression.body is BlockFunctionBody,
    FieldDeclaration() ||
    TopLevelVariableDeclaration() ||
    TypeAlias() ||
    Directive() => false,
    _ => true,
  };

  Doc enumBody(BlockEnumBody node) {
    final constants = node.constants;
    final members = node.members;
    if (members.isEmpty && node.semicolon == null) {
      return delimited(
        open: node.leftBracket,
        items: constants,
        close: node.rightBracket,
        settings: config.enumValues,
        spaceInside: true,
      );
    }
    final constantDocs = <Doc>[];
    for (final (i, constant) in constants.indexed) {
      constantDocs.add(visit(constant));
      if (i < constants.length - 1) {
        constantDocs.add(tok(constant.endToken.next));
        constantDocs.add(hardline);
        final blank = capBlank(blankLinesBetween(constant, constants[i + 1]));
        for (var b = 0; b < blank; b++) {
          constantDocs.add(hardline);
        }
      } else if (hasTrailingComma(constant)) {
        constantDocs.add(tok(constant.endToken.next));
      }
    }
    return braces(
      node.leftBracket,
      concat([
        ...constantDocs,
        tok(node.semicolon),
        if (members.isNotEmpty) ...[
          hardline,
          for (var b = 0; b < config.blankLinesBetweenMembers; b++) hardline,
          sequence(members, blankLines: _memberBlankLines),
        ],
      ]),
      node.rightBracket,
      after: members.isEmpty ? 0 : config.blankLinesAfterLastMember,
    );
  }

  Doc constructor(ConstructorDeclaration node) {
    final initializers = node.initializers;
    final redirected = node.redirectedConstructor;
    final parts = <(SyntacticEntity, Doc, Doc)>[];
    SyntacticEntity? previous;
    for (final child in node.childEntities) {
      if (child is Comment || child is Annotation) continue;
      if (identical(child, node.separator) ||
          identical(child, node.body) ||
          initializers.contains(child) ||
          identical(child, redirected)) {
        break;
      }
      final separator = previous == null ? empty : _separator(previous, child);
      parts.add((child, separator, _entity(child)));
      previous = child;
    }
    final body = node.body;
    final header = GroupId('constructor header');
    return concat([
      metadata(node),
      group(_header(parts), id: header),
      if (initializers.isNotEmpty)
        initializerList(node.separator!, initializers, header: header),
      if (redirected != null) ...[
        space,
        tok(node.separator),
        space,
        visit(redirected),
      ],
      _beforeBody(body),
      visit(body),
    ]);
  }

  Doc variableList(VariableDeclarationList node) {
    final variables = node.variables;
    final head = <Doc>[
      for (final annotation in node.metadata) ...[visit(annotation), space],
      for (final token in [node.lateKeyword, node.keyword])
        if (token != null) ...[tok(token), space],
      if (node.type != null) ...[visit(node.type), space],
    ];
    if (variables.length == 1) {
      return concat([...head, visit(variables.single)]);
    }
    return concat([...head, group(cont(commaSeparated(variables)))]);
  }

  Doc functionExpression(FunctionExpression node) {
    final body = node.body;
    return concat([
      visit(node.typeParameters),
      visit(node.parameters),
      if (node.parameters != null) _beforeBody(body),
      visit(body),
    ]);
  }

  /// The space before a function body: none before `;`, and before `=>`
  /// per `spaces.around_arrow`.
  Doc _beforeBody(FunctionBody body) => switch (body) {
    EmptyFunctionBody() => empty,
    ExpressionFunctionBody(keyword: null) when !config.spaceAroundArrow =>
      empty,
    _ => space,
  };

  Doc parameterList(FormalParameterList node) {
    final parameters = node.parameters;
    final leftDelimiter = node.leftDelimiter;
    return delimited(
      open: node.leftParenthesis,
      items: parameters,
      close: node.rightParenthesis,
      settings: config.parameters,
      spaceInside: config.spaceInsideParens,
      leftDelimiter: leftDelimiter,
      rightDelimiter: node.rightDelimiter,
      optionalStart: leftDelimiter == null
          ? -1
          : parameters.indexWhere((p) => p.offset > leftDelimiter.offset),
    );
  }
}
