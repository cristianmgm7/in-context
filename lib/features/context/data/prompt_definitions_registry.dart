import 'package:incontext/features/context/domain/entities/prompt_definition_entity.dart';

class PromptDefinitionsRegistry {
  PromptDefinitionsRegistry._();

  static final List<PromptDefinitionEntity> prompts = [
    const PromptDefinitionEntity(
      id: 'email-generator',
      name: 'Email Generator',
      description: 'Converts context into a professional email',
      version: '1.0.0',
      promptTemplate: '''
Based on the following context, generate a professional email:

{{CONTEXT}}

Generate a clear, concise, and professional email.
''',
    ),
    const PromptDefinitionEntity(
      id: 'todo-list',
      name: 'To-Do List',
      description: 'Extracts actionable tasks from context',
      version: '1.0.0',
      promptTemplate: '''
Based on the following context, extract a prioritized to-do list:

{{CONTEXT}}

Generate a markdown checklist of concrete action items.
''',
    ),
    const PromptDefinitionEntity(
      id: 'summary',
      name: 'Summary',
      description: 'Creates a concise summary of the context',
      version: '1.0.0',
      promptTemplate: '''
Summarize the following context in 2-3 concise paragraphs:

{{CONTEXT}}
''',
    ),
    const PromptDefinitionEntity(
      id: 'code-agent-prompt',
      name: 'Code Agent Prompt',
      description: 'Formats context as a detailed prompt for AI coding agents',
      version: '1.0.0',
      promptTemplate: '''
Transform the following context into a detailed, unambiguous prompt for a code generation agent:

{{CONTEXT}}

The output should be a clear technical specification that a code agent can execute.
''',
    ),
  ];

  static PromptDefinitionEntity? getById(String id) {
    try {
      return prompts.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}

