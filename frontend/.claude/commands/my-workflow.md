---
description: my-workflow
---
```mermaid
flowchart TD
    start_node_default([Start])
    end_node_default([End])
    prompt_1772038227107[refatore o codigo]

    start_node_default --> prompt_1772038227107
    prompt_1772038227107 --> end_node_default
```

## Workflow Execution Guide

Follow the Mermaid flowchart above to execute the workflow. Each node type has specific execution methods as described below.

### Execution Methods by Node Type

- **Rectangle nodes (Sub-Agent: ...)**: Execute Sub-Agents
- **Diamond nodes (AskUserQuestion:...)**: Use the AskUserQuestion tool to prompt the user and branch based on their response
- **Diamond nodes (Branch/Switch:...)**: Automatically branch based on the results of previous processing (see details section)
- **Rectangle nodes (Prompt nodes)**: Execute the prompts described in the details section below

### Prompt Node Details

#### prompt_1772038227107(refatore o codigo)

```
refatore o codigo

```
