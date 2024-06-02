---
# Source: automation-daily/templates/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: night-cron-rasterexport
spec:
  selector:
    app: night-cron-rasterexport
  ports:
    - protocol: TCP
      port: 80
      targetPort: 5000
  type: LoadBalancer
---
# Source: automation-daily/templates/cronjob.yaml
apiVersion: batch/v1beta1
kind: CronJob
metadata:
  name: night-cron-rasterexport
spec:
  schedule: 29 8 * * * # Adjust the schedule as needed
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: rasterexport-container
            image: acrarolibotnonprod.azurecr.io/automation/export-test-graph:3.2.4
            env:
            - name: callback_url
              value: "http://night-cron-rasterexport-route-qa.apps.j1lk3njp.eastus.aroapp.io/webhook"
            - name: certification
              value: ""
            - name: domain
              value: "RASTER"
            - name: export_count
              value: "1"
            - name: foot_prints_file
              value: "/layerSources/automation/nightly/files/footprints_5kmr_ayosh.txt"
            - name: image_name
              value: "export_callback_graph.png"
            - name: logger_name
              value: "export-test-daily"
            - name: logger_path
              value: "/layerSources/automation/nightly/logs"
            - name: path_to_products
              value: "/mnt/download"
            - name: record_id
              value: "70303cfb-4faa-4812-a934-33834e0182d2"
            - name: required_resolution
              value: "8.58306884765625e-05"
            - name: token
              value: "eyJhbGciOiJSUzI1NiIsImtpZCI6Ik1hcENvbG9uaWVzUUEifQ.eyJkIjpbInJhc3RlciIsInJhc3RlcldtcyIsInJhc3RlckV4cG9ydCIsImRlbSIsInZlY3RvciIsIjNkIl0sImlhdCI6MTY2Mzg2MzM0Mywic3ViIjoiTWFwQ29sb25pZXNRQSIsImlzcyI6Im1hcGNvbG9uaWVzLXRva2VuLWNsaSJ9.U_sx0Rsy96MA3xpIcWQHJ76xvK0PlHa--J1YILBYm2fCwtDdM4HLGagwq-OQQnBqi2e8KwktQ7sgt27hOJIPBHuONQS0ezBbuByk6UqN2S7P8WERdt8_lejuR1c94owQq7FOkhEaj_PKJ64ehXuMMHskfNeAIBf8GBN6QUGEenVx2w5k2rYBULoU30rpFkQVo8TtmiK2yGx0Ssx2k6LqSgCZfyZJbFzZ2MH3BPeCVleP1-zypaF9DS7SxS-EutL-gZ1e9bEccNktxQA4VMcjeTv45KYJLTIrccs_8gtPlzfaeNQFTIUKD-cRD1gyd_uLatPsl0wwHyFZIgRuJtcvfw"
            - name: trigger_task_create
              value: "export-tasks"
            - name: url
              value: "https://export-qa.mapcolonies.net"
            volumeMounts:
            - name: pvc-data
              mountPath: /layerSources
              subPath: ingestion-source
          restartPolicy: Never
          volumes:
          - name: pvc-data
            persistentVolumeClaim:
              claimName: internal-pvc-nfs
---
# Source: automation-daily/templates/cronjob.yaml
apiVersion: batch/v1beta1
kind: CronJob
metadata:
  name: night-cron-rasteringestion-job
spec:
  schedule: 29 8 * * * # Adjust the schedule as needed
  jobTemplate:
    spec:
      template:
        spec:
          serviceAccountName: automation
          initContainers:
          - name: wait-for-rasterexport
            image: bitnami/kubectl:1.27
            command:
                - sh
                - -c
                - |
                  #!/bin/bash

                  # Define the cron job prefix
                  CRONJOB_PREFIX="night-cron-rasterexport"
                  NAMESPACE="qa" # Replace with your namespace if different

                  # Function to get the job name based on the cron job prefix
                  get_job_name() {
                    kubectl get jobs -n "$NAMESPACE" --selector=job-name | awk '/^'"$CRONJOB_PREFIX"'/{print $1}'
                  }

                  # Wait for the job to appear
                  echo "Waiting for job with prefix $CRONJOB_PREFIX to appear..."
                  while true; do
                    JOB_NAME=$(get_job_name)
                    if [ -n "$JOB_NAME" ]; then
                      echo "Found job: $JOB_NAME"
                      break
                    fi
                    sleep 5
                  done

                  # Function to check if the job has completed
                  is_job_completed() {
                    kubectl get job "$JOB_NAME" -n "$NAMESPACE" -o jsonpath='{.status.succeeded}' | grep -q "1"
                  }

                  # Wait for the job to complete
                  echo "Waiting for job $JOB_NAME to complete..."
                  while true; do
                    if is_job_completed; then
                      echo "Job $JOB_NAME has completed successfully."
                      break
                    fi
                    sleep 5
                  done
          containers:
          - name: rasteringestion-container
            image: acrarolibotnonprod.azurecr.io/e2e_tests:1.1.9
            env:
            - name: CONF_FILE
              value: "/layerSources/test_dir/configurations/qa-configuration.json"
            - name: REPORTS_PATH
              value: "/layerSources/automation/nightly/logs"
            volumeMounts:
            - name: pvc-data
              mountPath: /layerSources
              subPath: ingestion-source
          restartPolicy: Never
          volumes:
          - name: pvc-data
            persistentVolumeClaim:
              claimName: internal-pvc-nfs
---
# Source: automation-daily/templates/cronjob.yaml
apiVersion: batch/v1beta1
kind: CronJob
metadata:
  name: night-cron-colletlogs-job
spec:
  schedule: 29 8 * * *  # Adjust the schedule as needed
  jobTemplate:
    spec:
      template:
        spec:
          serviceAccountName: automation
          initContainers:
          - name: wait-for-rasteringestion
            image: bitnami/kubectl:1.27
            command:
                - sh
                - -c
                - |
                  #!/bin/bash

                  # Define the cron job prefix
                  CRONJOB_PREFIX="night-cron-rasteringestion"
                  NAMESPACE="qa" # Replace with your namespace if different

                  # Function to get the job name based on the cron job prefix
                  get_job_name() {
                    kubectl get jobs -n "$NAMESPACE" --selector=job-name | awk '/^'"$CRONJOB_PREFIX"'/{print $1}'
                  }

                  # Wait for the job to appear
                  echo "Waiting for job with prefix $CRONJOB_PREFIX to appear..."
                  while true; do
                    JOB_NAME=$(get_job_name)
                    if [ -n "$JOB_NAME" ]; then
                      echo "Found job: $JOB_NAME"
                      break
                    fi
                    sleep 5
                  done

                  # Function to check if the job has completed
                  is_job_completed() {
                    kubectl get job "$JOB_NAME" -n "$NAMESPACE" -o jsonpath='{.status.succeeded}' | grep -q "1"
                  }

                  # Wait for the job to complete
                  echo "Waiting for job $JOB_NAME to complete..."
                  while true; do
                    if is_job_completed; then
                      echo "Job $JOB_NAME has completed successfully."
                      break
                    fi
                    sleep 5
                  done
          containers:
            - name: colletlogs-container
              image: acrarolibotnonprod.azurecr.io/automation/automation-collector:v3.9
              env:
              - name: folder_collect_logs
                value: "/layerSources/automation/nightly/logs"
              - name: logger_path
                value: "/layerSources/automation/nightly/logs"
              - name: pg_credential
                value: "{\"pg_host\": \"10.0.4.4\",\"pg_user\": \"postgres\",\"pg_port\": \"5432\",\"pg_pass\": \"Libot4allnonprod\",\"pg_db\": \"automation\",\"pg_schema\": \"public\",\"pg_table\": \"DailyTestResult\" }"
              - name: slack_url
                value: ""
              - name: tag_version
                value: "v1_cron"
              volumeMounts:
              - name: pvc-data
                mountPath: /layerSources
                subPath: ingestion-source
          restartPolicy: Never
          volumes:
          - name: pvc-data
            persistentVolumeClaim:
              claimName: internal-pvc-nfs
---
# Source: automation-daily/templates/route.yaml
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: night-cron-rasterexport-route
  annotations:
    {}
spec:
  to:
    kind: Service
    name: night-cron-rasterexport
    weight: 100
  port:
    targetPort: 80
