#include <stdint.h>

#include "motor.h"

#include "radio_control.h"
#include "pid_control.h"

#include "bound.h"

void attitude_pd_control(pid_control_t *pid, float ahrs_attitude,
	float setpoint_attitude, float angular_velocity)
{
	//error = setpoint - true_value
	pid->error_current = setpoint_attitude - ahrs_attitude;

	//error_derivative = error - error_last	
	//For angle, we can just take angular velocity to calculate */
	pid->error_derivative = angular_velocity;

	//pid_output = kp * error + kd * error_derivative
	pid->output =
		pid->kp * pid->error_current + pid->kd * pid->error_derivative;

	//Output boundary
	if(pid->output > pid->output_max) pid->output = pid->output_max;
	if(pid->output < pid->output_min) pid->output = pid->output_min;
}

void yaw_rate_p_control(pid_control_t *pid, float setpoint_yaw_rate, float angular_velocity)
{
	pid->error_current = setpoint_yaw_rate - angular_velocity;

	bound_float(&pid->output, pid->output_max, pid->output_min);
}

void motor_control(volatile float throttle_scale, uint16_t roll_pid_output, uint16_t pitch_pid_output,
	uint16_t yaw_pid_output)
{
	volatile uint16_t power_basis =
		(throttle_scale / 100.0) * (MOTOR_PULSE_MAX - MOTOR_PULSE_MIN) + MOTOR_PULSE_MIN;

	/* Quadrotor motor control */
	uint16_t motor1, motor2, motor3, motor4;

	motor1 = power_basis + roll_pid_output + pitch_pid_output + yaw_pid_output;
	motor2 = power_basis - roll_pid_output + pitch_pid_output - yaw_pid_output;
	motor3 = power_basis - roll_pid_output - pitch_pid_output + yaw_pid_output;
	motor4 = power_basis + roll_pid_output - pitch_pid_output - yaw_pid_output;

	bound_uint16(&motor1, MOTOR_PULSE_MAX, MOTOR_PULSE_MIN);
	bound_uint16(&motor2, MOTOR_PULSE_MAX, MOTOR_PULSE_MIN);
	bound_uint16(&motor3, MOTOR_PULSE_MAX, MOTOR_PULSE_MIN);
	bound_uint16(&motor4, MOTOR_PULSE_MAX, MOTOR_PULSE_MIN);

	//set_motor_pwm_pulse(MOTOR1, motor1);
	//set_motor_pwm_pulse(MOTOR2, motor2);
	//set_motor_pwm_pulse(MOTOR3, motor3);
	//set_motor_pwm_pulse(MOTOR4, motor4);
}
