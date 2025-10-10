package repositories

import (
	"database/sql"
	"fmt"
	"time"

	"pomodoro-backend/database"
	"pomodoro-backend/models"
)

type TaskRepository struct {
	db *sql.DB
}

func NewTaskRepository() *TaskRepository {
	return &TaskRepository{db: database.DB}
}

// GetTasks retrieves all tasks for a user
func (r *TaskRepository) GetTasks(userID string) ([]models.Task, error) {
	query := `
		SELECT id, user_id, title, description, priority, status, due_date, created_at, updated_at
		FROM tasks
		WHERE user_id = $1
		ORDER BY created_at DESC
	`

	rows, err := r.db.Query(query, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to query tasks: %w", err)
	}
	defer rows.Close()

	var tasks []models.Task
	for rows.Next() {
		var task models.Task
		err := rows.Scan(
			&task.ID, &task.UserID, &task.Title, &task.Description,
			&task.Priority, &task.Status, &task.DueDate,
			&task.CreatedAt, &task.UpdatedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan task: %w", err)
		}

		// Load subtasks for this task
		subtasks, err := r.GetSubtasks(task.ID)
		if err != nil {
			return nil, fmt.Errorf("failed to load subtasks: %w", err)
		}
		task.Subtasks = subtasks

		tasks = append(tasks, task)
	}

	if err = rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating tasks: %w", err)
	}

	return tasks, nil
}

// GetTask retrieves a single task by ID
func (r *TaskRepository) GetTask(taskID, userID string) (*models.Task, error) {
	query := `
		SELECT id, user_id, title, description, priority, status, due_date, created_at, updated_at
		FROM tasks
		WHERE id = $1 AND user_id = $2
	`

	var task models.Task
	err := r.db.QueryRow(query, taskID, userID).Scan(
		&task.ID, &task.UserID, &task.Title, &task.Description,
		&task.Priority, &task.Status, &task.DueDate,
		&task.CreatedAt, &task.UpdatedAt,
	)

	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("task not found")
		}
		return nil, fmt.Errorf("failed to query task: %w", err)
	}

	// Load subtasks
	subtasks, err := r.GetSubtasks(task.ID)
	if err != nil {
		return nil, fmt.Errorf("failed to load subtasks: %w", err)
	}
	task.Subtasks = subtasks

	return &task, nil
}

// CreateTask creates a new task
func (r *TaskRepository) CreateTask(userID string, req models.CreateTaskRequest) (*models.Task, error) {
	query := `
		INSERT INTO tasks (user_id, title, description, priority, due_date)
		VALUES ($1, $2, $3, $4, $5)
		RETURNING id, created_at, updated_at
	`

	var task models.Task
	task.UserID = userID
	task.Title = req.Title
	task.Description = req.Description
	task.Priority = req.Priority
	task.DueDate = req.DueDate
	task.Status = "pending"

	err := r.db.QueryRow(query, userID, req.Title, req.Description, req.Priority, req.DueDate).Scan(
		&task.ID, &task.CreatedAt, &task.UpdatedAt,
	)

	if err != nil {
		return nil, fmt.Errorf("failed to create task: %w", err)
	}

	return &task, nil
}

// UpdateTask updates an existing task
func (r *TaskRepository) UpdateTask(taskID, userID string, req models.UpdateTaskRequest) (*models.Task, error) {
	// Build dynamic update query
	setParts := []string{}
	args := []interface{}{}
	argIndex := 1

	if req.Title != nil {
		setParts = append(setParts, fmt.Sprintf("title = $%d", argIndex))
		args = append(args, *req.Title)
		argIndex++
	}
	if req.Description != nil {
		setParts = append(setParts, fmt.Sprintf("description = $%d", argIndex))
		args = append(args, *req.Description)
		argIndex++
	}
	if req.Priority != nil {
		setParts = append(setParts, fmt.Sprintf("priority = $%d", argIndex))
		args = append(args, *req.Priority)
		argIndex++
	}
	if req.Status != nil {
		setParts = append(setParts, fmt.Sprintf("status = $%d", argIndex))
		args = append(args, *req.Status)
		argIndex++
	}
	if req.DueDate != nil {
		setParts = append(setParts, fmt.Sprintf("due_date = $%d", argIndex))
		args = append(args, *req.DueDate)
		argIndex++
	}

	if len(setParts) == 0 {
		return r.GetTask(taskID, userID)
	}

	query := fmt.Sprintf(`
		UPDATE tasks
		SET %s
		WHERE id = $%d AND user_id = $%d
	`, joinStrings(setParts, ", "), argIndex, argIndex+1)

	args = append(args, taskID, userID)

	_, err := r.db.Exec(query, args...)
	if err != nil {
		return nil, fmt.Errorf("failed to update task: %w", err)
	}

	return r.GetTask(taskID, userID)
}

// DeleteTask deletes a task
func (r *TaskRepository) DeleteTask(taskID, userID string) error {
	query := `DELETE FROM tasks WHERE id = $1 AND user_id = $2`

	result, err := r.db.Exec(query, taskID, userID)
	if err != nil {
		return fmt.Errorf("failed to delete task: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to check deleted rows: %w", err)
	}

	if rowsAffected == 0 {
		return fmt.Errorf("task not found")
	}

	return nil
}

// GetSubtasks retrieves all subtasks for a task
func (r *TaskRepository) GetSubtasks(taskID string) ([]models.Subtask, error) {
	query := `
		SELECT id, task_id, title, completed, created_at, updated_at
		FROM subtasks
		WHERE task_id = $1
		ORDER BY created_at ASC
	`

	rows, err := r.db.Query(query, taskID)
	if err != nil {
		return nil, fmt.Errorf("failed to query subtasks: %w", err)
	}
	defer rows.Close()

	var subtasks []models.Subtask
	for rows.Next() {
		var subtask models.Subtask
		err := rows.Scan(
			&subtask.ID, &subtask.TaskID, &subtask.Title,
			&subtask.Completed, &subtask.CreatedAt, &subtask.UpdatedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan subtask: %w", err)
		}
		subtasks = append(subtasks, subtask)
	}

	return subtasks, nil
}

// CreateSubtask creates a new subtask
func (r *TaskRepository) CreateSubtask(taskID, userID string, req models.CreateSubtaskRequest) (*models.Subtask, error) {
	// First verify the task belongs to the user
	_, err := r.GetTask(taskID, userID)
	if err != nil {
		return nil, err
	}

	query := `
		INSERT INTO subtasks (task_id, title)
		VALUES ($1, $2)
		RETURNING id, created_at, updated_at
	`

	var subtask models.Subtask
	subtask.TaskID = taskID
	subtask.Title = req.Title
	subtask.Completed = false

	err = r.db.QueryRow(query, taskID, req.Title).Scan(
		&subtask.ID, &subtask.CreatedAt, &subtask.UpdatedAt,
	)

	if err != nil {
		return nil, fmt.Errorf("failed to create subtask: %w", err)
	}

	return &subtask, nil
}

// UpdateSubtask updates a subtask completion status
func (r *TaskRepository) UpdateSubtask(subtaskID, userID string, completed bool) error {
	query := `
		UPDATE subtasks
		SET completed = $1
		WHERE id = $2 AND task_id IN (
			SELECT id FROM tasks WHERE user_id = $3
		)
	`

	result, err := r.db.Exec(query, completed, subtaskID, userID)
	if err != nil {
		return fmt.Errorf("failed to update subtask: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to check updated rows: %w", err)
	}

	if rowsAffected == 0 {
		return fmt.Errorf("subtask not found")
	}

	return nil
}

// GetTasksByStatus retrieves tasks filtered by status
func (r *TaskRepository) GetTasksByStatus(userID, status string) ([]models.Task, error) {
	query := `
		SELECT id, user_id, title, description, priority, status, due_date, created_at, updated_at
		FROM tasks
		WHERE user_id = $1 AND status = $2
		ORDER BY created_at DESC
	`

	rows, err := r.db.Query(query, userID, status)
	if err != nil {
		return nil, fmt.Errorf("failed to query tasks by status: %w", err)
	}
	defer rows.Close()

	var tasks []models.Task
	for rows.Next() {
		var task models.Task
		err := rows.Scan(
			&task.ID, &task.UserID, &task.Title, &task.Description,
			&task.Priority, &task.Status, &task.DueDate,
			&task.CreatedAt, &task.UpdatedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan task: %w", err)
		}

		// Load subtasks
		subtasks, err := r.GetSubtasks(task.ID)
		if err != nil {
			return nil, fmt.Errorf("failed to load subtasks: %w", err)
		}
		task.Subtasks = subtasks

		tasks = append(tasks, task)
	}

	return tasks, nil
}

// GetCompletedTasksCount returns the count of completed tasks for today
func (r *TaskRepository) GetCompletedTasksCount(userID string, date time.Time) (int, error) {
	query := `
		SELECT COUNT(*)
		FROM tasks
		WHERE user_id = $1
		AND status = 'completed'
		AND DATE(updated_at) = DATE($2)
	`

	var count int
	err := r.db.QueryRow(query, userID, date).Scan(&count)
	if err != nil {
		return 0, fmt.Errorf("failed to count completed tasks: %w", err)
	}

	return count, nil
}

// UpdateTask updates an existing task
func (r *TaskRepository) UpdateTask(userID, taskID string, req models.UpdateTaskRequest) (*models.Task, error) {
	// Build dynamic update query
	setParts := []string{}
	args := []interface{}{}
	argIndex := 1

	if req.Title != nil {
		setParts = append(setParts, fmt.Sprintf("title = $%d", argIndex))
		args = append(args, *req.Title)
		argIndex++
	}
	if req.Description != nil {
		setParts = append(setParts, fmt.Sprintf("description = $%d", argIndex))
		args = append(args, *req.Description)
		argIndex++
	}
	if req.Priority != nil {
		setParts = append(setParts, fmt.Sprintf("priority = $%d", argIndex))
		args = append(args, *req.Priority)
		argIndex++
	}
	if req.Status != nil {
		setParts = append(setParts, fmt.Sprintf("status = $%d", argIndex))
		args = append(args, *req.Status)
		argIndex++
	}
	if req.DueDate != nil {
		setParts = append(setParts, fmt.Sprintf("due_date = $%d", argIndex))
		args = append(args, *req.DueDate)
		argIndex++
	}

	if len(setParts) == 0 {
		return nil, fmt.Errorf("no fields to update")
	}

	query := fmt.Sprintf(`
		UPDATE tasks
		SET %s, updated_at = NOW()
		WHERE id = $%d AND user_id = $%d
		RETURNING id, user_id, title, description, priority, status, due_date, created_at, updated_at`,
		joinStrings(setParts, ", "), argIndex, argIndex+1)

	args = append(args, taskID, userID)

	var task models.Task
	err := r.db.QueryRow(query, args...).Scan(
		&task.ID, &task.UserID, &task.Title, &task.Description,
		&task.Priority, &task.Status, &task.DueDate,
		&task.CreatedAt, &task.UpdatedAt,
	)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("task not found or access denied")
		}
		return nil, fmt.Errorf("failed to update task: %w", err)
	}

	// Load subtasks
	subtasks, err := r.GetSubtasks(task.ID)
	if err != nil {
		return nil, fmt.Errorf("failed to load subtasks: %w", err)
	}
	task.Subtasks = subtasks

	return &task, nil
}

// DeleteTask deletes a task
func (r *TaskRepository) DeleteTask(userID, taskID string) error {
	query := `DELETE FROM tasks WHERE id = $1 AND user_id = $2`
	result, err := r.db.Exec(query, taskID, userID)
	if err != nil {
		return fmt.Errorf("failed to delete task: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to check affected rows: %w", err)
	}

	if rowsAffected == 0 {
		return fmt.Errorf("task not found or access denied")
	}

	return nil
}

// Helper function to join strings
func joinStrings(strs []string, sep string) string {
	if len(strs) == 0 {
		return ""
	}
	if len(strs) == 1 {
		return strs[0]
	}

	result := strs[0]
	for i := 1; i < len(strs); i++ {
		result += sep + strs[i]
	}
	return result
}